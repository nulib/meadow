defmodule Meadow.BatchDriver do
  @moduledoc """
  IntervalTask to kickoff queued batch update/delete jobs
  """
  import Ecto.Query, warn: false
  require Logger

  alias Meadow.Batches
  alias Meadow.IntervalTask

  use IntervalTask, default_interval: 30_000, function: :drive_batch

  require Logger

  @timeout 600

  @doc """
  If no batches are currently running, find the next one and start it
  """
  def drive_batch(state) do
    with {:ok, count} <- Batches.purge_stalled(@timeout) do
      if count > 0 do
        Logger.info("Purging #{count} stalled #{Inflex.inflect("batch", count)} from queue")
      end
    end

    case Batches.next_batch() do
      nil ->
        :noop

      batch ->
        Logger.info("Found next batch to start #{inspect(batch)}")
        Batches.process_batch(batch)
    end

    {:noreply, state}
  end
end
