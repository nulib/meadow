defmodule Meadow.Notification.Heartbeat do
  @moduledoc """
  GenServer for sending periodic heartbeat notifications.
  """

  use GenServer
  require Logger
  alias Meadow.Notification

  @default_interval :timer.seconds(5)

  def start(message, info, interval \\ @default_interval) do
    Logger.info("Starting heartbeat for #{inspect(info)} every #{interval} ms")
    state = %{message: message, info: info, interval: interval}
    GenServer.start(__MODULE__, state)
  end

  def stop(pid) do
    if Process.alive?(pid) do
      state = GenServer.call(pid, :get_state)
      Logger.info("Stopping heartbeat for #{inspect(state.info)}")
      GenServer.stop(pid)
    else
      {:error, :not_open}
    end
  end

  @impl true
  def init(state) do
    schedule_heartbeat(state.interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:send_heartbeat, state) do
    Notification.publish(state.message, state.info)
    schedule_heartbeat(state.interval)
    {:noreply, state}
  end

  defp schedule_heartbeat(interval) do
    Process.send_after(self(), :send_heartbeat, interval)
  end
end
