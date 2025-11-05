defmodule MeadowWeb.Subscription do
  @moduledoc """
  Sends Meadow.Notification messages over Absinthe subscriptions.
  """

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Process.send_after(self(), :register, 500)
    {:ok, %{notifier_ref: nil}}
  end

  @impl true
  def handle_info({:notify, mutation_result, info}, state) do
    Absinthe.Subscription.publish(MeadowWeb.Endpoint, mutation_result, info)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{notifier_ref: ref} = state) do
    Process.send_after(self(), :register, 500)
    {:noreply, %{state | notifier_ref: nil}}
  end

  @impl true
  def handle_info(:register, state) do
    case register() do
      {:ok, ref} ->
        {:noreply, %{state | notifier_ref: ref}}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp register do
    if Meadow.Notification.alive?() do
      case Meadow.Notification.register(self()) do
        :ok ->
          {:ok, Process.monitor(Meadow.Notification)}

        error ->
          error
      end
    else
      Process.send_after(self(), :register, 500)
      nil
    end
  end
end
