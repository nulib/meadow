defmodule Meadow.Repo.Migrations.BackfillValueEntryIds do
  @moduledoc """
  Give every existing multivalued descriptive-metadata item a stable id.

  Repeating free-text fields are now stored as identified `ValueEntry` embeds
  (`{id, value}`), and notes/related URLs now carry an `id`. Existing works store
  those fields as bare-string arrays / id-less objects, which the new embedded
  schemas cannot load — so this migration rewrites the stored jsonb in place,
  minting an id for every item. It also stamps the newly-minted ids onto existing
  AI provenance (the one and only place item identity is recovered by value
  matching) so per-item attribution survives across the change.
  """
  use Ecto.Migration

  import Ecto.Query

  @value_entry_fields ~w(abstract alternate_title box_name box_number caption
    catalog_key citation cultural_context description folder_name folder_number
    identifier keywords legacy_identifier physical_description_material
    physical_description_size provenance publisher related_material rights_holder
    scope_and_contents series source table_of_contents)

  @id_bearing_object_fields ~w(notes related_url)

  def up do
    # Session-local helper: turn an array of strings (or id-less objects) into an
    # array of id-bearing objects. Strings become {id, value}; existing objects
    # gain an id if they lack one; anything else passes through.
    execute("""
    CREATE FUNCTION pg_temp.value_entries(arr jsonb) RETURNS jsonb AS $$
    DECLARE
      result jsonb := '[]'::jsonb;
      elem jsonb;
    BEGIN
      IF arr IS NULL OR jsonb_typeof(arr) <> 'array' THEN
        RETURN arr;
      END IF;

      FOR elem IN SELECT * FROM jsonb_array_elements(arr) LOOP
        IF jsonb_typeof(elem) = 'string' THEN
          result := result || jsonb_build_object('id', gen_random_uuid(), 'value', elem);
        ELSIF jsonb_typeof(elem) = 'object' AND NOT (elem ? 'id') THEN
          result := result || (elem || jsonb_build_object('id', gen_random_uuid()));
        ELSE
          result := result || elem;
        END IF;
      END LOOP;

      RETURN result;
    END;
    $$ LANGUAGE plpgsql;
    """)

    for field <- @value_entry_fields ++ @id_bearing_object_fields do
      execute("""
      UPDATE works
      SET descriptive_metadata = jsonb_set(
        descriptive_metadata, '{#{field}}',
        pg_temp.value_entries(descriptive_metadata->'#{field}')
      )
      WHERE descriptive_metadata ? '#{field}'
        AND jsonb_typeof(descriptive_metadata->'#{field}') = 'array';
      """)
    end

    flush()
    stamp_existing_provenance()
  end

  def down do
    # Flatten identified free-text items back to bare strings. Notes/related URLs
    # keep their (now harmless) ids.
    execute("""
    CREATE FUNCTION pg_temp.flatten_value_entries(arr jsonb) RETURNS jsonb AS $$
    DECLARE
      result jsonb := '[]'::jsonb;
      elem jsonb;
    BEGIN
      IF arr IS NULL OR jsonb_typeof(arr) <> 'array' THEN
        RETURN arr;
      END IF;

      FOR elem IN SELECT * FROM jsonb_array_elements(arr) LOOP
        IF jsonb_typeof(elem) = 'object' AND (elem ? 'value') THEN
          result := result || (elem->'value');
        ELSE
          result := result || elem;
        END IF;
      END LOOP;

      RETURN result;
    END;
    $$ LANGUAGE plpgsql;
    """)

    for field <- @value_entry_fields do
      execute("""
      UPDATE works
      SET descriptive_metadata = jsonb_set(
        descriptive_metadata, '{#{field}}',
        pg_temp.flatten_value_entries(descriptive_metadata->'#{field}')
      )
      WHERE descriptive_metadata ? '#{field}'
        AND jsonb_typeof(descriptive_metadata->'#{field}') = 'array';
      """)
    end
  end

  # Stamp the freshly minted work item ids onto existing AI provenance so per-item
  # attribution keys on ids from here on. Reuses the same finalize logic the live
  # apply paths use. Best-effort: a failure here must not fail the data migration,
  # which has already made every work loadable again.
  defp stamp_existing_provenance do
    alias Meadow.AI.Provenance
    alias Meadow.Data.Schemas.Work
    alias Meadow.Repo

    Repo.all(from(a in "ai_activities", where: not is_nil(a.work_id), select: a.id))
    |> Enum.each(fn activity_id ->
      activity = Provenance.get_activity!(activity_id)
      work = Repo.get(Work, activity.work_id)
      Provenance.finalize_applied_target_ids(activity, work)
    end)
  rescue
    error ->
      require Logger
      Logger.warning("Provenance id backfill skipped: #{Exception.message(error)}")
      :ok
  end
end
