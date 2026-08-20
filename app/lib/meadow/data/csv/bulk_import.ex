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
  alias Meadow.Data.Schemas.Work
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
        |> stream_rows()
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

  defp stream_rows(stream) do
    with timestamp <- NaiveDateTime.utc_now() do
      stream
      |> Stream.map(fn entry ->
        entry
        |> put_in([:inserted_at], timestamp)
        |> put_in([:updated_at], timestamp)
        |> update_in([:descriptive_metadata, :id], &(&1 || Ecto.UUID.generate()))
        |> update_in([:administrative_metadata, :id], &(&1 || Ecto.UUID.generate()))
        |> dump_coded_columns()
      end)
      |> Stream.chunk_every(@chunk_size)
      |> Stream.map(&stream_chunk_of_rows/1)
    end
  end

  # Top-level coded term columns (visibility, work_type) are stored as the bare
  # term id, so the COPY stream must carry the id rather than a JSON object.
  @coded_columns ~w(visibility work_type behavior)a

  defp dump_coded_columns(entry) do
    Enum.reduce(@coded_columns, entry, fn column, acc ->
      case Map.get(acc, column) do
        %{id: id} -> Map.put(acc, column, id)
        %{"id" => id} -> Map.put(acc, column, id)
        _ -> acc
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
