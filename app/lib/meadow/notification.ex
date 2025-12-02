defmodule Meadow.Notification do
  @moduledoc """
  GenServer for brokering notifications within Meadow.
  """

  use GenServer
  require Logger

  @doc "Check to see if notifier is alive"
  def alive?, do: not is_nil(GenServer.whereis(__MODULE__))

  @doc "Register a process to receive notifications"
  def register(pid), do: GenServer.call(__MODULE__, {:register, pid})

  @doc "List registered processes"
  def registered, do: GenServer.call(__MODULE__, :registered)

  @doc "Unregister a process from receiving notifications"
  def unregister(pid), do: GenServer.call(__MODULE__, {:unregister, pid})

  @doc "Publish a notification to all registered processes"
  def publish(result, info), do: GenServer.call(__MODULE__, {:publish, result, info})

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{registered: MapSet.new()}}
  end

  @impl true
  def handle_call({:register, pid}, _from, state) do
    registrant =
      Process.info(pid)
      |> Keyword.get(:registered_name, inspect(pid))

    if MapSet.member?(state.registered, pid) do
      {:reply, {:error, :already_registered}, state}
    else
      Logger.info("Registering #{registrant} for notifications")
      {:reply, :ok, %{state | registered: MapSet.put(state.registered, pid)}}
    end
  end

  @impl true
  def handle_call(:registered, _from, state) do
    {:reply, MapSet.to_list(state.registered), state}
  end

  @impl true
  def handle_call({:unregister, pid}, _from, state) do
    if MapSet.member?(state.registered, pid) do
      Logger.info("Unregistering #{inspect(pid)} from notifications")
      {:reply, :ok, %{state | registered: MapSet.delete(state.registered, pid)}}
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  @impl true
  def handle_call({:publish, result, info}, _from, state) do
    Enum.each(state.registered, fn pid ->
      send(pid, {:notify, result, info})
    end)

    {:reply, :ok, state}
  end
end
