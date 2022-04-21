defmodule Meadow.Data.PreservationChecks do
  @moduledoc """
  Create and manage preservation check jobs
  """
  use Meadow.Utils.Logging

  import Ecto.Query, warn: false
  require Logger

  alias Meadow.Data.PreservationCheckWriter
  alias Meadow.Data.Schemas.PreservationCheck
  alias Meadow.Repo

  # number of seconds after which to consider an active preservation check timed out
  @timeout 60 * 60 * 7

  def list_jobs do
    Repo.all(PreservationCheck)
  end

  def get_last_job do
    Repo.one(from j in PreservationCheck, order_by: [desc: j.inserted_at], limit: 1)
  end

  @doc """
  Returns a list of preservation checks matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:order, :asc}]
  """
  def list_jobs(criteria) do
    query = from(p in PreservationCheck)

    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from p in query, limit: ^limit

      {:order, order}, query ->
        from p in query, order_by: [{^order, :inserted_at}]
    end)
    |> Repo.all()
  end

  def create_job(attrs) do
    PreservationCheck.changeset(%PreservationCheck{}, attrs)
    |> Repo.insert()
  end

  def update_job(%PreservationCheck{} = job, attrs) do
    job
    |> PreservationCheck.changeset(attrs)
    |> Repo.update()
  end

  def update_job(job_id, attrs) do
    job = Repo.get!(PreservationCheck, job_id)
    update_job(job, attrs)
  end

  def start_job do
    with {:ok, count} <- purge_stalled(@timeout) do
      if count > 0 do
        Logger.warn("Timeout #{count} stalled #{Inflex.inflect("preservation checks", count)}")
      end
    end

    attrs = %{
      status: "active",
      active: "true",
      filename: "preservation_check_#{DateTime.utc_now() |> DateTime.to_unix(:millisecond)}.csv"
    }

    case create_job(attrs) do
      {:ok, job} ->
        with_log_metadata module: __MODULE__, id: job.id do
          Logger.info("Starting preservation check: #{job.id}")

          try do
            job
            |> generate_report()
          rescue
            exception ->
              Meadow.Error.report(exception, __MODULE__, __STACKTRACE__)
              Logger.error("Error for preservation check: #{job.id}")
              update_job(job, %{status: "error", active: false})
          end
        end

      {:error, %Ecto.Changeset{}} ->
        Logger.error("Active preservation check already running")

      {:error, _} ->
        Logger.error("Could not start preservation check.")
    end
  end

  defp generate_report(job) do
    case PreservationCheckWriter.generate_report(job.filename) do
      {:ok, s3_location, invalid_rows} ->
        [
          "Preservation check complete: #{job.id}.",
          "S3 location: #{s3_location}.",
          "Failures: #{invalid_rows}."
        ]
        |> Enum.join(" ")
        |> Logger.info()

        update_job(job, %{
          status: "complete",
          active: false,
          location: s3_location,
          invalid_rows: invalid_rows
        })

      _ ->
        Logger.error("Error for preservation check: #{job.id}")
        update_job(job, %{status: "error", active: false})
    end
  end

  defp purge_stalled(seconds) do
    {count, _} =
      stalled(seconds)
      |> Repo.update_all(
        set: [
          active: "false",
          status: "timeout",
          updated_at: DateTime.utc_now()
        ]
      )

    {:ok, count}
  end

  defp stalled(seconds) do
    timeout = DateTime.utc_now() |> DateTime.add(-seconds, :second)

    from(p in PreservationCheck,
      where:
        p.active == true and
          p.inserted_at <= ^timeout
    )
  end

  def increment_invalid_row_count(job_id) do
    from(j in PreservationCheck, update: [inc: [invalid_rows: 1]], where: j.id == ^job_id)
    |> Repo.update_all([])
  end
end
