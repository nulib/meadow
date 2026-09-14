defmodule Meadow.Data.CSV.BulkImport do
  @moduledoc """
  Functions to bulk import CSV Metadata Updates using PostgreSQL
  COPY/UPDATE
  """

  import Ecto.Query, only: [from: 2]

  alias Ecto.Adapters.SQL
  alias Ecto.Multi
  alias Meadow.AI.Provenance
  alias Meadow.Data.CSV.Import
  alias Meadow.Data.ItemIdentity
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Utils.Stream, as: StreamUtil
  alias NimbleCSV.RFC4180, as: CSV

  require Logger

  @chunk_size 500

  @doc """
  Bulk-update works from a CSV stream. Returns `{:ok, before_works}`, where
  `before_works` are pre-update snapshots of the works that carried applied AI
  provenance, ready for `record_ai_provenance/3`.

  Opens no transaction of its own: it is designed to run as an `Ecto.Multi`
  step inside the caller's transaction. Each chunk's work rows are locked
  `FOR UPDATE` before the AI provenance check, and those locks must be held
  until the caller commits.
  """
  def import_stream(stream, job_id, repo \\ Meadow.Repo) do
    temp_table = "works_" <> String.replace(job_id, "-", "")
    repo.query("CREATE TEMP TABLE #{temp_table} (LIKE works)")

    try do
      before_works =
        stream
        |> stream_rows(repo)
        |> Enum.flat_map(fn chunk ->
          update_chunk(temp_table, job_id, chunk, repo)
        end)
        |> Enum.uniq_by(& &1.id)

      {:ok, before_works}
    after
      repo.query("DROP TABLE #{temp_table}")
    end
  end

  def import_job(job) do
    stream =
      job.source
      |> StreamUtil.stream_from()
      |> Import.read_csv()
      |> Import.stream()

    Multi.new()
    |> Multi.run(:import, fn repo, _ -> import_stream(stream, job.id, repo) end)
    |> Multi.run(:provenance, fn repo, %{import: before_works} ->
      record_ai_provenance(before_works, job.user, repo)
    end)
    |> Meadow.Repo.transaction(timeout: :infinity)
    |> case do
      {:ok, %{import: before_works}} -> {:ok, before_works}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Record human mediation of AI-provenanced fields changed by a bulk import.
  Takes the before-update work snapshots returned by `import_stream/3` and,
  for each, compares against the updated work. Designed to run inside the same
  transaction as the import (the `Ecto.Multi` step after `import_stream/3`):
  recording is strict, so a failure returns `{:error, reason}` and rolls the
  whole import back instead of committing works with missing provenance.
  """
  def record_ai_provenance(before_works, actor, repo \\ Meadow.Repo) do
    Enum.each(before_works, fn before_work ->
      case repo.get(Work, before_work.id) do
        nil -> :ok
        after_work -> Provenance.record_work_manual_edit!(before_work, after_work, actor)
      end
    end)

    {:ok, before_works}
  rescue
    error ->
      Logger.warning("Failed to record bulk import provenance: #{Exception.message(error)}")
      {:error, error}
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

      before_works = snapshot_ai_provenanced_works(temp_table, repo)

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

      before_works
    end
  end

  # Lock the chunk's work rows (ids only) before reading provenance: without
  # the lock, a plan apply could add an applied AI target between the candidate
  # check and the bulk update, and that field's change would go unrecorded. The
  # locks are held until the import transaction commits.
  defp snapshot_ai_provenanced_works(temp_table, repo) do
    {:ok, %{rows: rows}} =
      repo.query(
        "SELECT works.id::text FROM works JOIN #{temp_table} ON works.id = #{temp_table}.id FOR UPDATE OF works"
      )

    case Provenance.work_ids_with_applied_ai_targets(List.flatten(rows), repo) do
      [] -> []
      ai_ids -> from(w in Work, where: w.id in ^ai_ids) |> repo.all()
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
  # (`ItemIdentity.reconcile/3` — the same rule the changeset applies). Without
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
          select: {type(w.id, Ecto.UUID), w.descriptive_metadata},
          lock: "FOR UPDATE"
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
        [_ | _] = items -> Map.put(acc, field, reconcile_items(field, items, existing, key_fun))
        _ -> acc
      end
    end)
  end

  defp reconcile_items(field, items, existing, key_fun) do
    current = existing |> Map.get(Atom.to_string(field)) |> List.wrap()

    case ItemIdentity.reconcile(items, current, key_fun) do
      {:ok, reconciled} ->
        reconciled

      {:error, reason} ->
        raise ArgumentError, "#{field} #{ItemIdentity.error_message(reason)}"
    end
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
