defmodule Meadow.Data.IndexWorker do
  @moduledoc """
  GenServer that reindexes
  """
  use GenServer
  require Logger
  alias Meadow.Data.Indexer

  @interval_milliseconds 120_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, Keyword.get(opts, :interval, @interval_milliseconds), [])
  end

  def init(interval) do
    Logger.info("Starting #{__MODULE__} with an indexing interval of #{interval}ms")
    Process.send_after(self(), :synchronize, interval)

    {:ok, interval}
  end

  def handle_info(:synchronize, interval) do
    Logger.info("Synchronizing the index...")
    Indexer.synchronize_index()

    Process.send_after(self(), :synchronize, interval)

    {:noreply, interval}
  end
end
