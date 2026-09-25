defmodule Meadow.Data.Schemas.ValueEntryBackfillTest do
  @moduledoc """
  Proves the legacy-data conversion at the heart of the backfill migration: a work
  whose repeating free-text fields are stored as bare-string arrays (the pre-embed
  shape) is rewritten to id-bearing `ValueEntry` objects and then loads cleanly
  through the new embedded schema.
  """
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Repo

  # The same transform the migration installs as a session-local function.
  @value_entries_fn """
  CREATE FUNCTION pg_temp.value_entries(arr jsonb) RETURNS jsonb AS $$
  DECLARE result jsonb := '[]'::jsonb; elem jsonb;
  BEGIN
    IF arr IS NULL OR jsonb_typeof(arr) <> 'array' THEN RETURN arr; END IF;
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
  END; $$ LANGUAGE plpgsql;
  """

  test "converts legacy bare-string arrays to loadable id-bearing ValueEntry items" do
    {:ok, work} = Works.create_work(%{accession_number: "legacy-1", descriptive_metadata: %{}})

    # Force the pre-migration storage shape directly in the column, bypassing the
    # schema (which could no longer produce it).
    Repo.query!(
      "UPDATE works SET descriptive_metadata = jsonb_set(descriptive_metadata, '{description}', '[\"Legacy A\", \"Legacy B\"]'::jsonb) WHERE id = $1",
      [Ecto.UUID.dump!(work.id)]
    )

    # Apply the migration's transform.
    Repo.query!(@value_entries_fn)

    Repo.query!(
      "UPDATE works SET descriptive_metadata = jsonb_set(descriptive_metadata, '{description}', pg_temp.value_entries(descriptive_metadata->'description')) WHERE id = $1",
      [Ecto.UUID.dump!(work.id)]
    )

    # The work now loads through the embedded ValueEntry schema, with a stable id
    # minted for each previously-bare value.
    loaded = Repo.get!(Work, work.id)
    entries = loaded.descriptive_metadata.description

    assert Enum.map(entries, & &1.value) == ["Legacy A", "Legacy B"]
    assert Enum.all?(entries, &match?({:ok, _}, Ecto.UUID.cast(&1.id)))
  end

  test "stamps ids onto id-less objects (legacy notes) and passes id-bearing ones through" do
    {:ok, work} = Works.create_work(%{accession_number: "legacy-2", descriptive_metadata: %{}})

    kept_id = Ecto.UUID.generate()

    legacy_notes = [
      %{"note" => "Id-less legacy note", "type" => %{"id" => "GENERAL_NOTE", "scheme" => "note_type"}},
      %{
        "id" => kept_id,
        "note" => "Already identified",
        "type" => %{"id" => "GENERAL_NOTE", "scheme" => "note_type"}
      }
    ]

    Repo.query!(
      "UPDATE works SET descriptive_metadata = jsonb_set(descriptive_metadata, '{notes}', $2::jsonb) WHERE id = $1",
      [Ecto.UUID.dump!(work.id), legacy_notes]
    )

    Repo.query!(@value_entries_fn)

    Repo.query!(
      "UPDATE works SET descriptive_metadata = jsonb_set(descriptive_metadata, '{notes}', pg_temp.value_entries(descriptive_metadata->'notes')) WHERE id = $1",
      [Ecto.UUID.dump!(work.id)]
    )

    [stamped, kept] = Repo.get!(Work, work.id).descriptive_metadata.notes

    assert stamped.note == "Id-less legacy note"
    assert match?({:ok, _}, Ecto.UUID.cast(stamped.id))
    assert kept.id == kept_id
    assert kept.note == "Already identified"
  end

  test "leaves non-array and empty-array values untouched" do
    Repo.query!(@value_entries_fn)

    assert %{rows: [[result]]} =
             Repo.query!("SELECT pg_temp.value_entries('[]'::jsonb)")

    assert result == []

    assert %{rows: [[result]]} =
             Repo.query!("SELECT pg_temp.value_entries('\"not an array\"'::jsonb)")

    assert result == "not an array"

    assert %{rows: [[result]]} = Repo.query!("SELECT pg_temp.value_entries(NULL::jsonb)")
    assert result == nil
  end

  test "the migration's field lists match the schema's identified fields" do
    # require_file returns nil when the file is already loaded; either way the
    # module is available afterwards.
    Code.require_file("priv/repo/migrations/20260701120000_backfill_value_entry_ids.exs")
    migration = Meadow.Repo.Migrations.BackfillValueEntryIds

    schema_fields =
      Meadow.Data.Schemas.WorkDescriptiveMetadata.value_entry_fields()
      |> Enum.map(&Atom.to_string/1)
      |> Enum.sort()

    assert Enum.sort(migration.value_entry_fields()) == schema_fields
    assert Enum.sort(migration.id_bearing_object_fields()) == ["notes", "related_url"]
  end
end
