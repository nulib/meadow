defmodule Meadow.Data.IndexWorker do
  @moduledoc """
  IntervalTask that reindexes
  """
  alias Meadow.Data.Indexer
  alias Meadow.IntervalTask
  use IntervalTask, default_interval: 1_000, function: :synchronize

  @impl IntervalTask
  def initial_state(_args), do: %{override: true}

  def synchronize(state) do
    Indexer.synchronize_index()
    {:noreply, state}
  end
end
