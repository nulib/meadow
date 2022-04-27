defmodule Meadow.Data.CSV.MetadataUpdateJobs do
  @moduledoc """
  Create and manage metadata update jobs
  """

  alias Ecto.{Changeset, Multi}
  alias Meadow.Data.ControlledTerms
  alias Meadow.Data.CSV.Import
  alias Meadow.Data.Schemas.{CSV.MetadataUpdateJob, Work}
  alias Meadow.Repo
  alias Meadow.Utils.ChangesetErrors
  alias Meadow.Utils.Stream, as: StreamUtil

  import Ecto.Query, warn: false

  @chunk_size 500
  @runnable_states ~w(pending valid)

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

    iex> create_job(%{source: "s3://upload-bucket/path/to/metadata.csv", user: "abc123"})
    iex> create_job(%{source: "file:///path/to/metadata.csv"})
  """
  def create_job(attrs) do
    if StreamUtil.exists?(attrs.source) do
      with attrs <- Map.merge(attrs, %{status: "pending"}) do
        MetadataUpdateJob.changeset(%MetadataUpdateJob{}, attrs)
        |> Repo.insert()
      end
    else
      {:error, "#{attrs.source} does not exist"}
    end
  end

  @doc """
  Update the status of an update job
  """
  def update_job(job, attrs) do
    job
    |> MetadataUpdateJob.changeset(attrs)
    |> Repo.update!()
  end

  defp validate_source(source) do
    validate_source(StreamUtil.exists?(source), source)
  end

  defp validate_source(true, source) do
    import_stream =
      StreamUtil.stream_from(source)
      |> Import.read_csv()

    {changesets, errors} =
      import_stream
      |> validate_headers()
      |> validate_terms()
      |> validate_rows()

    if Enum.empty?(errors),
      do: {:ok, length(changesets)},
      else: {:error, errors}
  end

  defp validate_source(false, source) do
    {:error, [%{row: 0, errors: %{source => "does not exist or cannot be read"}}]}
  end

  @doc """
  Run an update job
  """
  def apply_job(%MetadataUpdateJob{status: "pending"} = job) do
    job = update_job(job, %{status: "validating"})

    {:ok, job} =
      with_locked_job(job, fn ->
        case validate_source(job.source) do
          {:ok, rows} ->
            update_job(job, %{status: "valid", rows: rows})

          {:error, errors} ->
            update_job(job, %{status: "invalid", errors: errors})
        end
      end)

    case job do
      %{status: "valid"} -> apply_job(job)
      %{status: "invalid"} -> {:error, "validation", job}
      _ -> {:ok, job}
    end
  end

  def apply_job(%MetadataUpdateJob{source: source, status: "valid"} = job) do
    job = update_job(job, %{status: "processing", started_at: DateTime.utc_now()})

    multi =
      StreamUtil.stream_from(source)
      |> Import.read_csv()
      |> Import.stream()
      |> Enum.chunk_every(@chunk_size)
      |> Enum.reduce(Multi.new(), &apply_batch_of_works(&1, &2, job))
      |> Multi.update(job.id, MetadataUpdateJob.changeset(job, %{status: "complete"}))

    case with_locked_job(job, multi) do
      {:ok, result} ->
        {:ok, result |> Map.get(job.id)}

      {:error, id, changeset, _} ->
        update_job(job, %{status: "error"})

        {:error, id,
         ChangesetErrors.humanize_errors(changeset,
           flatten: [:administrative_metadata, :descriptive_metadata]
         )}
    end
  end

  def apply_job(%MetadataUpdateJob{status: status}),
    do: {:error, "Update Job cannot be applied: status is #{status}."}

  defp get_and_lock_job(%{id: job_id}) do
    from(j in MetadataUpdateJob, where: j.id == ^job_id, lock: "FOR UPDATE NOWAIT")
    |> Repo.one()
  end

  defp with_locked_job(job, func_or_multi) do
    Repo.transaction(
      fn ->
        get_and_lock_job(job)

        case Repo.transaction(func_or_multi, timeout: :infinity) do
          {:ok, result} -> result
          {:error, error} -> raise error
        end
      end,
      timeout: :infinity
    )
  end

  defp apply_batch_of_works(rows, multi, job) do
    with work_ids <- rows |> Enum.map(&Map.get(&1, :id)) do
      from(w in Work, where: w.id in ^work_ids, lock: "FOR UPDATE NOWAIT")
      |> Repo.all()
      |> Enum.reduce(multi, fn work, multi ->
        with row <- rows |> Enum.find(&(&1.id == work.id)) do
          multi
          |> Multi.update("update_#{row.id}", Work.update_changeset(work, row))
          |> Multi.insert_all("link_#{row.id}", "works_metadata_update_jobs", [
            %{
              metadata_update_job_id: dump_uuid(job.id),
              work_id: dump_uuid(work.id)
            }
          ])
        end
      end)
    end
  end

  defp dump_uuid(uuid) do
    case Ecto.UUID.dump(uuid) do
      {:ok, result} -> result
      other -> other
    end
  end

  def next_job do
    if from(m in MetadataUpdateJob, where: m.active == true) |> Repo.exists?(),
      do: nil,
      else:
        from(job in MetadataUpdateJob,
          where: job.status in @runnable_states,
          order_by: [asc: :inserted_at],
          limit: 1
        )
        |> Repo.one()
  end

  @doc """
  Finds stalled jobs and resets them to their last known state
  """
  def reset_stalled(seconds) do
    with timeout <- DateTime.utc_now() |> DateTime.add(-seconds, :second) do
      {:ok, {pending_canceled, pending_count}} = reset_stalled("validating", "pending", timeout)
      {:ok, {valid_canceled, valid_count}} = reset_stalled("processing", "valid", timeout)
      {:ok, pending_canceled + valid_canceled, pending_count + valid_count}
    end
  end

  defp reset_stalled(stuck_status, reset_status, timeout) do
    {:ok, result} =
      Repo.transaction(fn ->
        with {cancel_count, _} <- cancel_after_retries(stuck_status, timeout),
             {reset_count, _} <- change_stalled_status(stuck_status, reset_status, timeout) do
          {:ok, {cancel_count, reset_count}}
        end
      end)

    result
  end

  defp change_stalled_status(stuck_status, reset_status, timeout) do
    ids_to_reset =
      from(job in MetadataUpdateJob,
        where: job.status == ^stuck_status and job.updated_at <= ^timeout,
        lock: "FOR UPDATE SKIP LOCKED",
        select: job.id
      )
      |> Repo.all()

    from(job in MetadataUpdateJob, where: job.id in ^ids_to_reset)
    |> Repo.update_all(
      set: [
        active: false,
        status: reset_status,
        updated_at: DateTime.utc_now()
      ],
      inc: [retries: 1]
    )
  end

  defp cancel_after_retries(status, timeout, retries \\ 3) do
    error = %{row: 0, errors: %{status: ["Stuck in #{status} after #{retries} retries"]}}

    from(
      job in MetadataUpdateJob,
      where: job.status == ^status and job.updated_at <= ^timeout and job.retries >= ^retries
    )
    |> Repo.update_all(
      set: [
        active: false,
        status: "error",
        updated_at: DateTime.utc_now()
      ],
      push: [errors: error]
    )
  end

  defp errors_with_row(errors, row) do
    if Enum.empty?(errors), do: [], else: [%{row: row, errors: errors}]
  end

  defp validate_headers(%{headers: headers} = import_stream) do
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

      errors = (missing ++ extra) |> Enum.into(%{})
      {import_stream, errors |> errors_with_row(1)}
    end
  end

  defp validate_headers([] = import_stream) do
    {import_stream, errors_with_row(%{headers: ["could not identify header row"]}, 1)}
  end

  defp validate_terms({import_stream, errors}) when errors == [] do
    errors =
      import_stream
      |> Import.stream()
      |> ControlledTerms.extract_unique_terms()
      |> Enum.map(&{&1, ControlledTerms.fetch(&1)})
      |> Enum.filter(fn
        {_, {:error, _}} -> true
        _ -> false
      end)
      |> Enum.map(fn
        {term, {:error, 404}} -> {term, "is an unknown term"}
        {term, {:error, :unknown_authority}} -> {term, "is from an unknown authority"}
        {term, {:error, reason}} -> {term, "failed validation because: #{reason}"}
      end)
      |> Enum.into(%{})

    {import_stream, errors |> errors_with_row(0)}
  end

  defp validate_terms(other), do: other

  defp validate_rows({import_stream, errors}) when errors == [] do
    changesets =
      import_stream
      |> Import.stream()
      |> Stream.chunk_every(@chunk_size)
      |> Stream.flat_map(&validate_chunk_of_rows/1)
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

  defp validate_rows(other), do: other

  defp validate_chunk_of_rows(rows) do
    with existing_ids <- get_chunk_of_ids(rows) do
      rows
      |> Stream.map(fn row ->
        with changeset <- Work.changeset(%Work{}, row) do
          if is_nil(row.id),
            do: Changeset.add_error(changeset, :id, "is required"),
            else: changeset |> validate_id_and_accession(row, existing_ids)
        end
      end)
    end
  end

  defp validate_id_and_accession(changeset, row, existing_ids) do
    with %{id: id, accession_number: accession_number} <- row do
      case Map.get(existing_ids, id) do
        ^accession_number -> changeset
        :invalid_uuid -> changeset |> Changeset.add_error(:id, "is not a valid UUID")
        nil -> changeset |> Changeset.add_error(:id, "not found")
        _ -> changeset |> Changeset.add_error(:accession_number, "does not match")
      end
    end
  end

  defp get_chunk_of_ids(rows) do
    work_ids = Enum.map(rows, & &1.id)

    uuids =
      work_ids
      |> Enum.filter(fn id ->
        case Ecto.UUID.cast(id) do
          {:ok, _} -> true
          :error -> false
        end
      end)

    invalid_results = (work_ids -- uuids) |> Enum.map(&{&1, :invalid_uuid})

    valid_results =
      from(w in Work, where: w.id in ^uuids, select: {w.id, w.accession_number})
      |> Repo.all()

    (valid_results ++ invalid_results)
    |> Enum.into(%{})
  end
end
