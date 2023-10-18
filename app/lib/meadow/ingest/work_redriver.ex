defmodule Meadow.Ingest.WorkRedriver do
  @moduledoc """
  IntervalTask to create works from pending ingest sheet rows
  """
  use Meadow.Utils.Logging

  import Ecto.Query, warn: false

  alias Meadow.Ingest.Progress
  alias Meadow.IntervalTask
  alias Meadow.Repo

  use IntervalTask, default_interval: 60_000, function: :redrive_works

  require Logger

  @timeout 60

  @doc """
  Find works that have been processing longer than @timeout and
  reset them to pending
  """
  def redrive_works(state) do
    with_log_level :info do
      {count, _} =
        Progress.works_processing_longer_than(@timeout)
        |> Repo.update_all(set: [status: "pending", updated_at: DateTime.utc_now()])

      if count > 0,
        do: Logger.warning("Redriving #{count} works processing longer than #{@timeout} seconds")
    end

    {:noreply, state}
  end
end
