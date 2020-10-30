defmodule Meadow.Data.IndexWorker do
  @moduledoc """
  BackgroundTask that reindexes
  """
  alias Meadow.BackgroundTask
  alias Meadow.Data.Indexer
  use BackgroundTask, default_interval: 120_000, function: :synchronize

  @impl BackgroundTask
  def before_init(_args), do: {:ok, %{override: true}}

  def synchronize(state) do
    Indexer.synchronize_index()
    {:noreply, state}
  end
end
