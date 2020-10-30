defmodule Meadow.Ingest.WorkRedriver do
  @moduledoc """
  BackgroundTask to create works from pending ingest sheet rows
  """
  import Ecto.Query, warn: false
  import Meadow.Utils.Logging

  alias Meadow.BackgroundTask
  alias Meadow.Ingest.Progress
  alias Meadow.Repo

  use BackgroundTask, default_interval: 60_000, function: :redrive_works

  require Logger

  @timeout 60

  @doc """
  Find works that have been processing longer than @timeout and
  reset them to pending
  """
  def redrive_works(state) do
    with_log_level(:info, fn ->
      {count, _} =
        Progress.works_processing_longer_than(@timeout)
        |> Repo.update_all(set: [status: "pending", updated_at: DateTime.utc_now()])

      if count > 0,
        do: Logger.info("Redriving #{count} works processing longer than #{@timeout} seconds")
    end)

    {:noreply, state}
  end
end
