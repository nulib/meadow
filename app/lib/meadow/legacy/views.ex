defmodule Meadow.Legacy.Views do
  @moduledoc """
  Read-only views that present `works` and `file_sets` the way they looked
  before the metadata tables existed, with the jsonb columns reassembled in
  place. They are a transitional aid for anyone used to the old shapes; nothing
  in the application reads them.

  The views live in a `legacy` schema so they can keep the original table
  names, so `SET search_path TO legacy, public` makes an old query work again:

      SELECT descriptive_metadata->>'title' FROM legacy_works;

  Two deliberate gaps:

    * `date_created` entries carry only `edtf`. The `humanized` rendering is
      produced by `Meadow.Data.Types.EDTFDate` on load and has no SQL
      equivalent.
    * The old embeds carried a generated `id`, which one-row-per-work tables
      have no place for, so `descriptive_metadata` and `administrative_metadata`
      have no `id` key.

  The DDL is generated from the schema declarations and the live catalog, so
  `create!/0` is safe to re-run (`CREATE OR REPLACE`) after a field is added.
  """

  alias Meadow.Data.Schemas.{NoteEntry, RelatedURLEntry, WorkAdministrativeMetadata}
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata, as: Descriptive
  alias Meadow.Repo

  # Columns replaced by a generated expression, so they are not passed through
  @replaced %{
    "works" =>
      ~w(visibility work_type behavior descriptive_metadata administrative_metadata),
    "file_sets" =>
      ~w(role core_metadata structural_metadata extracted_metadata derivatives)
  }

  @top_level_schemes %{
    "visibility" => "visibility",
    "work_type" => "work_type",
    "behavior" => "behavior",
    "role" => "file_set_role"
  }

  @doc """
  Create (or recreate) the legacy schema, rebuild function and views.

  The views are dropped first rather than replaced: `CREATE OR REPLACE VIEW`
  refuses to change a view's column list, so replacing in place would fail the
  first time a metadata field is added or removed.
  """
  def create! do
    Repo.query!("DROP VIEW IF EXISTS legacy_works")
    Repo.query!("DROP VIEW IF EXISTS legacy_file_sets")
    Repo.query!(extracted_document_function())
    Repo.query!(works_view())
    Repo.query!(file_sets_view())
    :ok
  end

  @doc "Remove the legacy schema and everything in it"
  def drop! do
    Repo.query!("DROP VIEW IF EXISTS legacy_works")
    Repo.query!("DROP VIEW IF EXISTS legacy_file_sets")
    :ok
  end

  # ---------------------------------------------------------------------------
  # works

  defp works_view do
    """
    CREATE OR REPLACE VIEW legacy_works AS
    SELECT
      #{passthrough("works", "w")},
      #{coded_column("w", "visibility")} AS visibility,
      #{coded_column("w", "work_type")} AS work_type,
      #{coded_column("w", "behavior")} AS behavior,
      #{descriptive_object()} AS descriptive_metadata,
      #{administrative_object()} AS administrative_metadata
    FROM works w
    LEFT JOIN work_descriptive_metadata d ON d.work_id = w.id
    LEFT JOIN work_administrative_metadata a ON a.work_id = w.id
    #{dates_lateral()}
    #{places_lateral()}
    #{entry_lateral(NoteEntry)}
    #{entry_lateral(RelatedURLEntry)}
    #{controlled_lateral()}
    """
  end

  defp descriptive_object do
    parts =
      value_pairs(Descriptive, "d", :values) ++
        value_pairs(Descriptive, "d", :string) ++
        coded_pairs(Descriptive, "d") ++
        [
          ~s|'#{field_of(Descriptive, :dates)}', dc.value|,
          ~s|'#{field_of(Descriptive, :places)}', np.value|,
          "'notes', notes.value",
          "'related_url', related_url.value",
          "'inserted_at', to_jsonb(d.inserted_at)",
          "'updated_at', to_jsonb(d.updated_at)"
        ]

    """
    jsonb_build_object(
          #{Enum.join(parts, ",\n          ")}
        ) || (#{empty_controlled()}::jsonb || COALESCE(ce.value, '{}'::jsonb))
    """
    |> String.trim()
  end

  defp administrative_object do
    parts =
      value_pairs(WorkAdministrativeMetadata, "a", :values) ++
        value_pairs(WorkAdministrativeMetadata, "a", :string) ++
        coded_pairs(WorkAdministrativeMetadata, "a") ++
        [
          "'inserted_at', to_jsonb(a.inserted_at)",
          "'updated_at', to_jsonb(a.updated_at)"
        ]

    "jsonb_build_object(\n          #{Enum.join(parts, ",\n          ")}\n        )"
  end

  defp value_pairs(schema, alias_, kind),
    do: for(f <- schema.__metadata__(:fields, kind), do: ~s|'#{f}', to_jsonb(#{alias_}.#{f})|)

  defp coded_pairs(schema, alias_) do
    for f <- schema.__metadata__(:fields, :coded) do
      ~s|'#{f}', CASE WHEN #{alias_}.#{f}_id IS NULL THEN 'null'::jsonb | <>
        ~s|ELSE jsonb_build_object('id', #{alias_}.#{f}_id, 'scheme', '#{f}') END|
    end
  end

  defp coded_column(alias_, column) do
    scheme = Map.fetch!(@top_level_schemes, column)

    "CASE WHEN #{alias_}.#{column} IS NULL THEN 'null'::jsonb " <>
      "ELSE jsonb_build_object('id', #{alias_}.#{column}, 'scheme', '#{scheme}') END"
  end

  # Controlled fields default to an empty list, as the embeds did
  defp empty_controlled do
    Descriptive.__metadata__(:fields, :controlled)
    |> Enum.map_join(", ", &~s|"#{&1}": []|)
    |> then(&"'{#{&1}}'")
  end

  defp field_of(schema, kind), do: schema.__metadata__(:fields, kind) |> hd()

  # ---------------------------------------------------------------------------
  # laterals

  defp dates_lateral do
    """
    LEFT JOIN LATERAL (
      SELECT COALESCE(jsonb_agg(jsonb_build_object('edtf', e) ORDER BY ord), '[]'::jsonb) AS value
      FROM unnest(d.#{field_of(Descriptive, :dates)}) WITH ORDINALITY t(e, ord)
    ) dc ON true
    """
    |> String.trim()
  end

  defp places_lateral do
    """
    LEFT JOIN LATERAL (
      SELECT COALESCE(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
               'id', e->>'place_id', 'label', e->>'label', 'summary', e->>'summary',
               'coordinates', CASE WHEN e->'longitude' IS NOT NULL AND e->'latitude' IS NOT NULL
                                   THEN jsonb_build_array(e->'longitude', e->'latitude') END
             )) ORDER BY ord), '[]'::jsonb) AS value
      FROM jsonb_array_elements(d.#{field_of(Descriptive, :places)}) WITH ORDINALITY t(e, ord)
    ) np ON true
    """
    |> String.trim()
  end

  defp entry_lateral(NoteEntry), do: entry_lateral("notes", "work_notes", "note", "type", "note_type")

  defp entry_lateral(RelatedURLEntry),
    do: entry_lateral("related_url", "work_related_urls", "url", "label", "related_url")

  defp entry_lateral(name, table, text_column, coded_name, scheme) do
    """
    LEFT JOIN LATERAL (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
               '#{text_column}', e.#{text_column},
               '#{coded_name}', jsonb_build_object('id', e.#{coded_name}_id, 'scheme', '#{scheme}')
             ) ORDER BY e."position"), '[]'::jsonb) AS value
      FROM #{table} e WHERE e.work_id = w.id
    ) #{name} ON true
    """
    |> String.trim()
  end

  defp controlled_lateral do
    """
    LEFT JOIN LATERAL (
      SELECT jsonb_object_agg(field, entries) AS value FROM (
        SELECT c.field, jsonb_agg(jsonb_build_object(
                 'term', c.term_id,
                 'role', CASE WHEN c.role_id IS NULL THEN 'null'::jsonb
                              ELSE jsonb_build_object('id', c.role_id, 'scheme', c.role_scheme) END
               ) ORDER BY c."position") AS entries
        FROM work_controlled_entries c WHERE c.work_id = w.id GROUP BY c.field
      ) g
    ) ce ON true
    """
    |> String.trim()
  end

  # ---------------------------------------------------------------------------
  # file sets

  defp file_sets_view do
    """
    CREATE OR REPLACE VIEW legacy_file_sets AS
    SELECT
      #{passthrough("file_sets", "f")},
      #{coded_column("f", "role")} AS role,
      jsonb_strip_nulls(jsonb_build_object(
        'location', c.location,
        'original_filename', c.original_filename,
        'description', c.description,
        'label', c.label,
        'alt_text', c.alt_text,
        'image_caption', c.image_caption,
        'mime_type', c.mime_type,
        'digests', CASE
                     WHEN c.digest_md5 IS NULL AND c.digest_sha1 IS NULL AND c.digest_sha256 IS NULL
                     THEN NULL
                     ELSE jsonb_strip_nulls(jsonb_build_object(
                            'md5', c.digest_md5, 'sha1', c.digest_sha1, 'sha256', c.digest_sha256))
                   END,
        'inserted_at', c.inserted_at,
        'updated_at', c.updated_at
      )) AS core_metadata,
      CASE WHEN s.file_set_id IS NULL THEN NULL
           ELSE jsonb_build_object('type', s.type, 'value', s.value) END AS structural_metadata,
      COALESCE(dv.value, '{}'::jsonb) AS derivatives,
      COALESCE(em.value, '{}'::jsonb) AS extracted_metadata
    FROM file_sets f
    LEFT JOIN file_set_core_metadata c ON c.file_set_id = f.id
    LEFT JOIN file_set_structural_metadata s ON s.file_set_id = f.id
    LEFT JOIN LATERAL (
      SELECT jsonb_object_agg(dd.kind, dd.location) AS value
      FROM file_set_derivatives dd WHERE dd.file_set_id = f.id
    ) dv ON true
    LEFT JOIN LATERAL (
      SELECT jsonb_object_agg(x.tool, legacy_extracted_document(x.id)) AS value
      FROM file_set_extracted_metadata x WHERE x.file_set_id = f.id
    ) em ON true
    """
  end

  # The flattened entries table stores one row per node with its `path`; this
  # folds the tree back up one depth at a time. A recursive CTE cannot do it,
  # because aggregates are not allowed in the recursive term.
  defp extracted_document_function do
    """
    CREATE OR REPLACE FUNCTION legacy_extracted_document(meta_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE AS $fn$
    DECLARE
      max_depth int;
      d int;
      acc jsonb := '{}'::jsonb;
      rec record;
      node jsonb;
      sep constant text := chr(31);
    BEGIN
      SELECT max(cardinality(path)) INTO max_depth
        FROM file_set_extracted_metadata_entries WHERE extracted_metadata_id = meta_id;

      IF max_depth IS NULL THEN RETURN NULL; END IF;

      FOR d IN REVERSE max_depth..0 LOOP
        FOR rec IN
          SELECT path, value_type, value
          FROM file_set_extracted_metadata_entries
          WHERE extracted_metadata_id = meta_id AND cardinality(path) = d
        LOOP
          IF rec.value_type = 'object' THEN
            SELECT COALESCE(
                     jsonb_object_agg(c.path[d + 1], acc -> array_to_string(c.path, sep)),
                     '{}'::jsonb)
              INTO node
              FROM file_set_extracted_metadata_entries c
             WHERE c.extracted_metadata_id = meta_id
               AND cardinality(c.path) = d + 1
               AND c.path[1:d] IS NOT DISTINCT FROM rec.path;

          ELSIF rec.value_type = 'array' THEN
            SELECT COALESCE(
                     jsonb_agg(acc -> array_to_string(c.path, sep) ORDER BY (c.path[d + 1])::int),
                     '[]'::jsonb)
              INTO node
              FROM file_set_extracted_metadata_entries c
             WHERE c.extracted_metadata_id = meta_id
               AND cardinality(c.path) = d + 1
               AND c.path[1:d] IS NOT DISTINCT FROM rec.path;

          ELSE
            node := CASE rec.value_type
                      WHEN 'string'  THEN to_jsonb(rec.value)
                      WHEN 'integer' THEN to_jsonb(rec.value::bigint)
                      WHEN 'float'   THEN to_jsonb(rec.value::double precision)
                      WHEN 'boolean' THEN to_jsonb(rec.value::boolean)
                      ELSE 'null'::jsonb
                    END;
          END IF;

          acc := jsonb_set(acc, ARRAY[array_to_string(rec.path, sep)], node, true);
        END LOOP;
      END LOOP;

      RETURN acc -> '';
    END $fn$
    """
  end

  # ---------------------------------------------------------------------------

  # Every column of the base table that the view does not replace, read from the
  # catalog so a new column shows up the next time the views are created
  defp passthrough(table, alias_) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        [table]
      )

    replaced = Map.fetch!(@replaced, table)

    rows
    |> List.flatten()
    |> Enum.reject(&(&1 in replaced))
    |> Enum.map_join(", ", &~s|#{alias_}."#{&1}"|)
  end
end
