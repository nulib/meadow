defmodule Meadow.CSVMetadataUpdateDriver do
  @moduledoc """
  IntervalTask to kickoff queued CSV metadata update jobs
  """
  import Ecto.Query, warn: false
  require Logger

  alias Meadow.Data.CSV.MetadataUpdateJobs
  alias Meadow.IntervalTask

  use IntervalTask, default_interval: 5_000, function: :drive_update_job
  use Meadow.Utils.Logging

  require Logger

  @timeout 360

  @doc """
  If no metadata update jobs are currently running, find the next one and start it
  """
  def drive_update_job(state) do
    MetadataUpdateJobs.reset_stalled(@timeout)
    |> log_reset_stalled()

    case MetadataUpdateJobs.next_job() do
      nil ->
        :noop

      job ->
        Logger.info("Starting CSV update job #{job.id}")

        with_log_metadata module: MetadataUpdateJobs, id: job.id do
          MetadataUpdateJobs.apply_job(job)
        end
    end

    {:noreply, state}
  end

  defp log_reset_stalled({:ok, cancel_count, reset_count}) do
    log_cancel(cancel_count)
    log_reset(reset_count)
  end

  defp log_cancel(0), do: :noop

  defp log_cancel(count) do
    "Canceling #{count} #{Inflex.inflect("update job", count)} jobs for exceeding max retries"
    |> Logger.info()
  end

  defp log_reset(0), do: :noop

  defp log_reset(count) do
    "Resetting #{count} stalled #{Inflex.inflect("update job", count)}"
    |> Logger.info()
  end
end
