defmodule Meadow.Data.CSV.BulkImport do
  @moduledoc """
  Functions to bulk import CSV Metadata Updates using PostgreSQL
  COPY/UPDATE
  """

  alias Ecto.Adapters.SQL
  alias Meadow.Data.CSV.Import
  alias Meadow.Data.ItemIdentity
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Utils.Stream, as: StreamUtil
  alias NimbleCSV.RFC4180, as: CSV

  import Ecto.Query, only: [from: 2]

  @chunk_size 500

  def import_stream(stream, job_id, repo \\ Meadow.Repo) do
    with temp_table <- "works_" <> String.replace(job_id, "-", "") do
      repo.transaction(
        fn ->
          repo.query("CREATE TEMP TABLE #{temp_table} (LIKE works)")

          try do
            stream
            |> stream_rows(repo)
            |> Stream.map(fn chunk ->
              update_chunk(temp_table, job_id, chunk, repo)
            end)
            |> Stream.run()
          after
            repo.query("DROP TABLE #{temp_table}")
          end
        end,
        timeout: :infinity
      )
    end
  end

  def import_job(job) do
    job.source
    |> StreamUtil.stream_from()
    |> Import.read_csv()
    |> Import.stream()
    |> import_stream(job.id)
  end

  defp update_chunk(temp_table, job_id, stream, repo) do
    with [header_row] <- stream |> Enum.take(1),
         rows <- stream |> Stream.drop(1),
         set_clause <-
           header_row
           |> String.split(~r/\s*,\s*/)
           |> Enum.map_join(", ", &"#{&1} = #{temp_table}.#{&1}"),
         sql <-
           "COPY #{temp_table} (#{header_row}) FROM STDIN WITH (FORMAT CSV, NULL '')" do
      rows |> Enum.into(SQL.stream(repo, sql))
      # credo:disable-for-previous-line Credo.Check.Warning.UnusedEnumOperation

      repo.query(
        "UPDATE #{temp_table} SET inserted_at = works.inserted_at FROM works WHERE #{temp_table}.id = works.id"
      )

      repo.query(
        "UPDATE works SET #{set_clause} FROM #{temp_table} WHERE works.id = #{temp_table}.id"
      )

      repo.query(
        "INSERT INTO works_metadata_update_jobs (metadata_update_job_id, work_id) SELECT '#{job_id}', id FROM #{temp_table}"
      )

      repo.query("TRUNCATE TABLE #{temp_table}")
    end
  end

  defp stream_rows(stream, repo) do
    timestamp = NaiveDateTime.utc_now()

    stream
    |> Stream.chunk_every(@chunk_size)
    |> Stream.map(fn chunk ->
      chunk
      |> rehydrate_item_ids(repo)
      |> Enum.map(&normalize_row(&1, timestamp))
      |> stream_chunk_of_rows()
    end)
  end

  defp normalize_row(entry, timestamp) do
    entry
    |> put_in([:inserted_at], timestamp)
    |> put_in([:updated_at], timestamp)
    |> update_in([:descriptive_metadata, :id], &(&1 || Ecto.UUID.generate()))
    |> update_in([:administrative_metadata, :id], &(&1 || Ecto.UUID.generate()))
    # This path writes descriptive_metadata jsonb directly (no changeset), so
    # repeating free-text fields must be well-formed identified ValueEntry maps
    # (ids not recovered by rehydration above are minted fresh here).
    |> update_in([:descriptive_metadata], &WorkDescriptiveMetadata.jsonb_value_entries/1)
  end

  # Recover stable item ids before the direct-jsonb write. Exported cells
  # round-trip each free-text item's id (`uuid:value`), but hand-authored cells
  # and notes/related URLs arrive id-less; those keep their identity when their
  # content exactly matches one of the work's current items
  # (`ItemIdentity.rehydrate/3` — the same rule the changeset applies). Without
  # this, every CSV metadata update would remint ids and silently detach
  # per-item AI provenance from untouched items.
  defp rehydrate_item_ids(chunk, repo) do
    existing = existing_metadata(Enum.map(chunk, &Map.get(&1, :id)), repo)

    Enum.map(chunk, fn entry ->
      update_in(
        entry,
        [:descriptive_metadata],
        &rehydrate_metadata(&1, Map.get(existing, Map.get(entry, :id)))
      )
    end)
  end

  defp existing_metadata(work_ids, repo) do
    case Enum.filter(work_ids, &valid_uuid?/1) do
      [] ->
        %{}

      ids ->
        from(w in "works",
          where: w.id in type(^ids, {:array, Ecto.UUID}),
          select: {type(w.id, Ecto.UUID), w.descriptive_metadata}
        )
        |> repo.all()
        |> Map.new()
    end
  end

  defp valid_uuid?(id), do: is_binary(id) and match?({:ok, _}, Ecto.UUID.cast(id))

  defp rehydrate_metadata(metadata, existing) when is_map(metadata) and is_map(existing) do
    metadata
    |> rehydrate_fields(
      WorkDescriptiveMetadata.value_entry_fields(),
      existing,
      &ItemIdentity.value_key/1
    )
    |> rehydrate_fields([:notes], existing, &ItemIdentity.note_key/1)
    |> rehydrate_fields([:related_url], existing, &ItemIdentity.related_url_key/1)
  end

  defp rehydrate_metadata(metadata, _existing), do: metadata

  defp rehydrate_fields(metadata, fields, existing, key_fun) do
    Enum.reduce(fields, metadata, fn field, acc ->
      case Map.get(acc, field) do
        [_ | _] = items ->
          current = existing |> Map.get(Atom.to_string(field)) |> List.wrap()
          Map.put(acc, field, ItemIdentity.rehydrate(items, current, key_fun))

        _ ->
          acc
      end
    end)
  end

  defp stream_chunk_of_rows(chunk) do
    Stream.resource(
      fn -> :header end,
      fn
        nil ->
          {:halt, nil}

        :header ->
          {
            [chunk |> List.first() |> Map.keys() |> Enum.map(&to_string/1)]
            |> CSV.dump_to_stream(),
            :rows
          }

        :rows ->
          {
            chunk
            |> Enum.map(fn entry ->
              entry
              |> Enum.map(fn
                {_, %NaiveDateTime{} = v} -> NaiveDateTime.to_iso8601(v)
                {_, v} when is_list(v) or is_map(v) -> Jason.encode!(v)
                {_, v} -> to_string(v)
              end)
            end)
            |> CSV.dump_to_stream(),
            nil
          }
      end,
      fn _ -> :ok end
    )
    |> Stream.map(&IO.iodata_to_binary/1)
  end
end
