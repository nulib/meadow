defmodule Meadow.Data.ReindexWorker do
  @moduledoc """
  IntervalTask that reindexes from V1 to V2
  """
  alias Meadow.Data.Reindexer
  alias Meadow.IntervalTask

  use IntervalTask, default_interval: 1_000, function: :synchronize

  @impl IntervalTask
  def initial_state(_args),
    do: %{override: true, tasks: %{}}

  def synchronize(%{tasks: tasks} = state) do
    tasks = Reindexer.synchronize(tasks)
    {:noreply, Map.replace(state, :tasks, tasks)}
  end
end
