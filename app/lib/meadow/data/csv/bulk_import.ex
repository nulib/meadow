defmodule Meadow.Data.CSV.BulkImport do
  @moduledoc """
  Apply a validated CSV metadata update to works, one chunk of rows at a time,
  through `Work.update_changeset/2`. Each row is cast with the same changeset
  the work editor uses, so repeating values keep their ids when unchanged,
  new values get fresh ids, and invalid data fails the job.
  """

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias Meadow.AI.Provenance
  alias Meadow.Data.CSV.Import
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Utils.Stream, as: StreamUtil

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
    before_works =
      stream
      |> Stream.chunk_every(@chunk_size)
      |> Enum.flat_map(fn chunk -> update_chunk(job_id, chunk, repo) end)
      |> Enum.uniq_by(& &1.id)

    {:ok, before_works}
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
        nil ->
          :ok

        after_work ->
          Provenance.record_work_manual_edit!(
            before_work,
            Work.preload_metadata(after_work),
            actor
          )
      end
    end)

    {:ok, before_works}
  rescue
    error ->
      Logger.warning("Failed to record bulk import provenance: #{Exception.message(error)}")
      {:error, error}
  end

  defp update_chunk(job_id, rows, repo) do
    ids = rows |> Enum.map(& &1.id) |> Enum.reject(&is_nil/1)

    works =
      from(w in Work, where: w.id in ^ids, lock: "FOR UPDATE")
      |> Works.with_metadata()
      |> repo.all()
      |> Map.new(&{&1.id, &1})

    before_works = snapshot_ai_provenanced_works(works, repo)

    Enum.each(rows, fn row ->
      case Map.fetch(works, row.id) do
        {:ok, work} ->
          work
          |> Work.update_changeset(Map.drop(row, [:id, :inserted_at, :updated_at]))
          |> Ecto.Changeset.force_change(:updated_at, DateTime.utc_now())
          |> repo.update!()

        :error ->
          raise ArgumentError, "work #{row.id} not found"
      end
    end)

    repo.insert_all(
      "works_metadata_update_jobs",
      Enum.map(ids, fn id ->
        %{metadata_update_job_id: Ecto.UUID.dump!(job_id), work_id: Ecto.UUID.dump!(id)}
      end),
      on_conflict: :nothing
    )

    before_works
  end

  # Works are already locked `FOR UPDATE` by `update_chunk/3`, so a plan apply
  # cannot slip an applied AI target in between the candidate check and the
  # update; the snapshot is the fully preloaded pre-update struct.
  defp snapshot_ai_provenanced_works(works, repo) do
    case Provenance.work_ids_with_applied_ai_targets(Map.keys(works), repo) do
      [] -> []
      ai_ids -> Enum.map(ai_ids, &Map.fetch!(works, &1))
    end
  end
end
