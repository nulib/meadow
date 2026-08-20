defmodule Meadow.Repo.Migrations.CreateFileSetMetadataTables do
  @moduledoc """
  Move file set metadata out of the `file_sets` jsonb columns into tables:

    * `file_set_core_metadata` (one row per file set, digests as columns)
    * `file_set_structural_metadata` (at most one row per file set)
    * `file_set_derivatives` (one row per derivative kind)
    * `file_set_extracted_metadata` (one row per tool, with typed dimensions)
      and `file_set_extracted_metadata_entries` (the flattened tool document)

  Existing data is backfilled from the jsonb columns, which stay in place until
  the cleanup migration. `down/0` drops the new tables.
  """

  use Ecto.Migration

  require Logger

  @tables ~w(file_set_core_metadata file_set_structural_metadata file_set_derivatives
    file_set_extracted_metadata file_set_extracted_metadata_entries)
  @published ~w(file_set_core_metadata file_set_structural_metadata file_set_derivatives file_set_extracted_metadata)

  def up do
    create_tables()
    flush()

    execute("ALTER PUBLICATION events DROP TABLE file_sets")
    backfill()
    flush()
    backfill_extracted_metadata()
    verify!()

    execute("ALTER PUBLICATION events ADD TABLE file_sets, #{Enum.join(@published, ", ")}")
    Enum.each(@published, &execute("ALTER TABLE #{&1} REPLICA IDENTITY FULL"))
  end

  def down do
    execute("ALTER PUBLICATION events DROP TABLE #{Enum.join(@published, ", ")}")
    Enum.each(Enum.reverse(@tables), &execute("DROP TABLE IF EXISTS #{&1}"))
  end

  defp create_tables do
    create table(:file_set_core_metadata, primary_key: false) do
      add(:file_set_id, references(:file_sets, type: :uuid, on_delete: :delete_all),
        primary_key: true
      )

      add(:location, :text, null: false)
      add(:original_filename, :text, null: false)
      add(:description, :text)
      add(:label, :text)
      add(:alt_text, :text)
      add(:image_caption, :text)
      add(:mime_type, :text)
      add(:digest_md5, :text)
      add(:digest_sha1, :text)
      add(:digest_sha256, :text)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:file_set_core_metadata, [:mime_type]))
    create(index(:file_set_core_metadata, [:location]))

    create table(:file_set_structural_metadata, primary_key: false) do
      add(:file_set_id, references(:file_sets, type: :uuid, on_delete: :delete_all),
        primary_key: true
      )

      add(:type, :text)
      add(:value, :text)
    end

    create table(:file_set_derivatives, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:file_set_id, references(:file_sets, type: :uuid, on_delete: :delete_all), null: false)
      add(:kind, :text, null: false)
      add(:location, :text)
    end

    create(unique_index(:file_set_derivatives, [:file_set_id, :kind]))

    create table(:file_set_extracted_metadata, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:file_set_id, references(:file_sets, type: :uuid, on_delete: :delete_all), null: false)
      add(:tool, :text, null: false)
      add(:tool_version, :text)
      add(:width, :integer)
      add(:height, :integer)
      add(:duration_ms, :float)
    end

    create(
      constraint(:file_set_extracted_metadata, :tool_must_be_known,
        check: "tool IN ('exif', 'mediainfo')"
      )
    )

    create(unique_index(:file_set_extracted_metadata, [:file_set_id, :tool]))

    create table(:file_set_extracted_metadata_entries, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :extracted_metadata_id,
        references(:file_set_extracted_metadata, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:path, {:array, :text}, null: false)
      add(:value_type, :text, null: false)
      add(:value, :text)
    end

    create(
      constraint(:file_set_extracted_metadata_entries, :value_type_must_be_known,
        check:
          "value_type IN ('object', 'array', 'string', 'integer', 'float', 'boolean', 'null')"
      )
    )

    create(index(:file_set_extracted_metadata_entries, [:extracted_metadata_id]))
    create(index(:file_set_extracted_metadata_entries, [:path]))
  end

  defp backfill do
    Logger.info("Backfilling file_set_core_metadata")

    execute("""
    INSERT INTO file_set_core_metadata
      (file_set_id, location, original_filename, description, label, alt_text, image_caption, mime_type,
       digest_md5, digest_sha1, digest_sha256, inserted_at, updated_at)
    SELECT fs.id,
           COALESCE(fs.core_metadata->>'location', ''),
           COALESCE(fs.core_metadata->>'original_filename', ''),
           fs.core_metadata->>'description',
           fs.core_metadata->>'label',
           fs.core_metadata->>'alt_text',
           fs.core_metadata->>'image_caption',
           fs.core_metadata->>'mime_type',
           fs.core_metadata->'digests'->>'md5',
           fs.core_metadata->'digests'->>'sha1',
           fs.core_metadata->'digests'->>'sha256',
           COALESCE((fs.core_metadata->>'inserted_at')::timestamp, fs.inserted_at),
           COALESCE((fs.core_metadata->>'updated_at')::timestamp, fs.updated_at)
    FROM file_sets fs
    """)

    Logger.info("Backfilling file_set_structural_metadata")

    execute("""
    INSERT INTO file_set_structural_metadata (file_set_id, type, value)
    SELECT fs.id, fs.structural_metadata->>'type', fs.structural_metadata->>'value'
    FROM file_sets fs
    WHERE jsonb_typeof(fs.structural_metadata) = 'object'
      AND (fs.structural_metadata->>'type' IS NOT NULL OR fs.structural_metadata->>'value' IS NOT NULL)
    """)

    Logger.info("Backfilling file_set_derivatives")

    execute("""
    INSERT INTO file_set_derivatives (file_set_id, kind, location)
    SELECT fs.id, d.key, CASE WHEN jsonb_typeof(d.value) = 'string' THEN d.value #>> '{}' ELSE NULL END
    FROM file_sets fs
    CROSS JOIN LATERAL jsonb_each(CASE WHEN jsonb_typeof(fs.derivatives) = 'object' THEN fs.derivatives ELSE '{}'::jsonb END) d
    """)
  end

  # The tool documents are arbitrarily nested, so they are flattened in Elixir
  # (mirroring Meadow.Data.FileSets.ExtractedMetadata) one file set at a time
  defp backfill_extracted_metadata do
    Logger.info("Backfilling file_set_extracted_metadata")

    %{rows: rows} =
      repo().query!("""
      SELECT id::text, extracted_metadata::text FROM file_sets
      WHERE jsonb_typeof(extracted_metadata) = 'object' AND extracted_metadata <> '{}'::jsonb
      """)

    Enum.each(rows, fn [file_set_id, json] ->
      json
      |> Jason.decode!()
      |> Enum.each(fn {tool, document} -> insert_tool!(file_set_id, tool, document) end)
    end)
  end

  defp insert_tool!(file_set_id, tool, document) when tool in ["exif", "mediainfo"] do
    document = if is_map(document), do: document, else: %{}
    dims = dimensions(tool, document)

    %{rows: [[metadata_id]]} =
      repo().query!(
        """
        INSERT INTO file_set_extracted_metadata (file_set_id, tool, tool_version, width, height, duration_ms)
        VALUES ($1::uuid, $2, $3, $4, $5, $6) RETURNING id::text
        """,
        [file_set_id, tool, document["tool_version"], dims.width, dims.height, dims.duration_ms]
      )

    document
    |> flatten()
    |> Enum.chunk_every(500)
    |> Enum.each(fn chunk ->
      {placeholders, params} =
        chunk
        |> Enum.with_index()
        |> Enum.map_reduce([], fn {%{path: path, value_type: type, value: value}, i}, acc ->
          base = i * 4

          {"($#{base + 1}::uuid, $#{base + 2}::text[], $#{base + 3}, $#{base + 4})",
           acc ++ [metadata_id, path, type, value]}
        end)

      repo().query!(
        "INSERT INTO file_set_extracted_metadata_entries (extracted_metadata_id, path, value_type, value) VALUES #{Enum.join(placeholders, ", ")}",
        params
      )
    end)
  end

  defp insert_tool!(file_set_id, tool, _document) do
    Logger.warning(
      "Skipping unknown extracted metadata tool #{inspect(tool)} on file set #{file_set_id}"
    )
  end

  defp flatten(document, path \\ [])

  defp flatten(%{} = map, path),
    do: [
      %{path: path, value_type: "object", value: nil}
      | Enum.flat_map(map, fn {k, v} -> flatten(v, path ++ [to_string(k)]) end)
    ]

  defp flatten(list, path) when is_list(list) do
    children =
      list
      |> Enum.with_index()
      |> Enum.flat_map(fn {v, i} -> flatten(v, path ++ [Integer.to_string(i)]) end)

    [%{path: path, value_type: "array", value: nil} | children]
  end

  defp flatten(value, path) when is_binary(value),
    do: [%{path: path, value_type: "string", value: value}]

  defp flatten(value, path) when is_integer(value),
    do: [%{path: path, value_type: "integer", value: Integer.to_string(value)}]

  defp flatten(value, path) when is_float(value),
    do: [%{path: path, value_type: "float", value: Float.to_string(value)}]

  defp flatten(value, path) when is_boolean(value),
    do: [%{path: path, value_type: "boolean", value: to_string(value)}]

  defp flatten(nil, path), do: [%{path: path, value_type: "null", value: nil}]
  defp flatten(value, path), do: [%{path: path, value_type: "string", value: inspect(value)}]

  defp dimensions("exif", %{"value" => %{} = value}),
    do: %{
      width: to_int(value["ImageWidth"]),
      height: to_int(value["ImageHeight"]),
      duration_ms: nil
    }

  defp dimensions("mediainfo", %{"value" => %{"media" => %{"track" => tracks}}})
       when is_list(tracks) do
    general = Enum.at(tracks, 0) || %{}
    video = Enum.at(tracks, 1) || %{}

    %{
      width: to_int(video["Width"]),
      height: to_int(video["Height"]),
      duration_ms: duration_ms(general["Duration"])
    }
  end

  defp dimensions(_, _), do: %{width: nil, height: nil, duration_ms: nil}

  defp to_int(value) when is_integer(value), do: value
  defp to_int(value) when is_float(value), do: trunc(value)

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp to_int(_), do: nil

  defp duration_ms(value) when is_number(value), do: value * 1000.0

  defp duration_ms(value) when is_binary(value) do
    case Float.parse(value) do
      {seconds, _} -> seconds * 1000
      :error -> nil
    end
  end

  defp duration_ms(_), do: nil

  defp verify! do
    file_sets = count!("SELECT count(*) FROM file_sets")
    core = count!("SELECT count(*) FROM file_set_core_metadata")

    unless file_sets == core,
      do: raise("Expected #{file_sets} core metadata rows, backfilled #{core}")

    expected_derivatives =
      count!("""
      SELECT COALESCE(sum((SELECT count(*) FROM jsonb_object_keys(fs.derivatives))), 0)::bigint
      FROM file_sets fs WHERE jsonb_typeof(fs.derivatives) = 'object'
      """)

    derivatives = count!("SELECT count(*) FROM file_set_derivatives")

    unless expected_derivatives == derivatives,
      do: raise("Expected #{expected_derivatives} derivatives, backfilled #{derivatives}")

    Logger.info(
      "Backfilled #{core} file sets, #{derivatives} derivatives, " <>
        "#{count!("SELECT count(*) FROM file_set_structural_metadata")} structural metadata rows, " <>
        "#{count!("SELECT count(*) FROM file_set_extracted_metadata")} extracted metadata documents"
    )
  end

  defp count!(sql) do
    %{rows: [[count]]} = repo().query!(sql)
    count || 0
  end
end
