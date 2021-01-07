defmodule Meadow.Data.CSV.MetadataUpdateJobs do
  @moduledoc """
  Create and manage metadata update jobs
  """

  alias Ecto.Multi
  alias Meadow.Data.CSV.Import
  alias Meadow.Data.Schemas.{CSV.MetadataUpdateJob, Work}
  alias Meadow.Repo
  alias Meadow.Utils.ChangesetErrors

  import Ecto.Query, warn: false

  @chunk_size 500

  @doc """
  Retrieve a list of update jobs
  """
  def list_jobs do
    from(job in MetadataUpdateJob, order_by: [desc: job.updated_at])
    |> Repo.all()
  end

  @doc """
  Retrieve an update job by its ID
  """
  def get_job(id) do
    Repo.get!(MetadataUpdateJob, id)
  end

  @doc """
  Create an update job record from a source location URI

  Examples:

    iex> create_job("s3://upload-bucket/path/to/metadata.csv")
    iex> create_job("file:///path/to/metadata.csv")
  """
  def create_job(source_location) do
    MetadataUpdateJob.changeset(%MetadataUpdateJob{}, %{
      source: source_location,
      status: "pending"
    })
    |> Repo.insert()
  end

  @doc """
  Update the status of an update job
  """
  def update_job_status(job, status) do
    job
    |> MetadataUpdateJob.changeset(%{status: status})
    |> Repo.update!()
  end

  defp validate_source(source) do
    validate_source(Meadow.Utils.Stream.exists?(source), source)
  end

  defp validate_source(true, source) do
    import_stream = Meadow.Utils.Stream.stream_from(source) |> Import.read_csv()

    {changesets, errors} = do_validate(import_stream, validate_headers(import_stream.headers))

    if Enum.empty?(errors),
      do: {:ok, length(changesets)},
      else: {:error, errors}
  end

  defp validate_source(false, source) do
    {:error, [%{source => "does not exist or cannot be read"}]}
  end

  @doc """
  Run an update job
  """
  def apply_job(%MetadataUpdateJob{status: "pending"} = job) do
    update_job_status(job, "validating")

    case validate_source(job.source) do
      {:ok, rows} ->
        MetadataUpdateJob.changeset(job, %{status: "valid", rows: rows})
        |> Repo.update!()
        |> apply_job()

      {:error, errors} ->
        {:error, "validation",
         MetadataUpdateJob.changeset(job, %{
           status: "invalid",
           errors: errors
         })
         |> Repo.update!()}
    end
  end

  def apply_job(%MetadataUpdateJob{source: source, status: "valid"} = job) do
    update_job_status(job, "processing")

    multi =
      Meadow.Utils.Stream.stream_from(source)
      |> Import.read_csv()
      |> Import.stream()
      |> Enum.chunk_every(@chunk_size)
      |> Enum.reduce(Multi.new(), &apply_batch_of_works/2)
      |> Multi.update(job.id, MetadataUpdateJob.changeset(job, %{status: "complete"}))

    case Repo.transaction(multi, timeout: :infinity) do
      {:ok, result} ->
        {:ok, result |> Map.get(job.id)}

      {:error, id, changeset, _} ->
        update_job_status(job, "error")

        {:error, id,
         ChangesetErrors.humanize_errors(changeset,
           flatten: [:administrative_metadata, :descriptive_metadata]
         )}
    end
  end

  def apply_job(%MetadataUpdateJob{status: status}),
    do: {:error, "Update Job cannot be applied: status is #{status}."}

  defp apply_batch_of_works(rows, multi) do
    with work_ids <- rows |> Enum.map(&Map.get(&1, :id)) do
      from(w in Work, where: w.id in ^work_ids, lock: "FOR UPDATE NOWAIT")
      |> Repo.all()
      |> Enum.reduce(multi, fn work, multi ->
        with row <- rows |> Enum.find(&(&1.id == work.id)) do
          Multi.update(multi, row.id, Work.update_changeset(work, row))
        end
      end)
    end
  end

  def next_job do
    from(job in MetadataUpdateJob,
      where: job.status in ["pending", "valid"],
      order_by: [asc: :updated_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Finds stalled jobs and resets them to their last known state
  """
  def reset_stalled(seconds) do
    with timeout <- DateTime.utc_now() |> DateTime.add(-seconds, :second) do
      {pending_count, _} = reset_stalled("validating", "pending", timeout)
      {valid_count, _} = reset_stalled("processing", "valid", timeout)

      {:ok, pending_count + valid_count}
    end
  end

  defp reset_stalled(stuck_status, reset_status, timeout) do
    from(job in MetadataUpdateJob,
      where: job.status == ^stuck_status and job.updated_at <= ^timeout
    )
    |> Repo.update_all(
      set: [
        status: reset_status,
        updated_at: DateTime.utc_now()
      ]
    )
  end

  defp do_validate(import_stream, header_errors) when map_size(header_errors) == 0 do
    changesets =
      import_stream
      |> Import.stream()
      |> Stream.map(fn row -> Work.changeset(%Work{}, row) end)
      |> Enum.with_index(3)

    errors =
      changesets
      |> Enum.reject(fn {changeset, _} -> changeset.valid? end)
      |> Enum.map(fn {changeset, index} ->
        %{
          row: index,
          errors:
            ChangesetErrors.humanize_errors(changeset,
              flatten: [:administrative_metadata, :descriptive_metadata]
            )
        }
      end)
      |> Enum.to_list()

    {changesets, errors}
  end

  defp do_validate(_, header_errors) do
    {[], [%{row: 1, errors: header_errors}]}
  end

  defp validate_headers(headers) do
    with expected <- Import.fields() do
      missing =
        (expected -- headers)
        |> Enum.map(fn missing_field ->
          {missing_field, ["is missing"]}
        end)

      extra =
        (headers -- expected)
        |> Enum.map(fn missing_field ->
          {missing_field, ["is unknown"]}
        end)

      (missing ++ extra) |> Enum.into(%{})
    end
  end
end
