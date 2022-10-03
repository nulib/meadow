defmodule Meadow.Data.IndexWorker do
  @moduledoc """
  IntervalTask that reindexes
  """
  alias Meadow.Data.Indexer
  alias Meadow.IntervalTask
  use IntervalTask, default_interval: 1_000, function: :synchronize

  require Logger

  @impl IntervalTask
  def initial_state(args) do
    case Keyword.get(args, :version) do
      nil -> raise ArgumentError, "Cannot start IndexWorker without a :version argument"
      version -> %{version: version}
    end
  end

  def synchronize(state) do
    Logger.info("Synchronizing search index v#{state.version}")
    Indexer.synchronize_index(state.version)
    {:noreply, state}
  end
end
