defmodule MeadowWeb.IngestJobChannel do
  @moduledoc """
  Facilitates communication between Phoenix.PubSub and Websocket client
  """

  use Phoenix.Channel
  alias Meadow.Ingest.InventoryValidator

  def join("job:" <> _job_id, _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "joined", %{channel: socket.topic})
    {:noreply, socket}
  end

  def handle_in("state", payload, socket) do
    payload
    |> payload_id()
    |> Meadow.Notification.dump()

    {:noreply, socket}
  end

  def handle_in("validate", payload, socket) do
    job_id =
      payload
      |> payload_id()
      |> String.split(":")
      |> List.last()

    InventoryValidator.validate(job_id)
    {:noreply, socket}
  end

  defp payload_id(payload), do: Map.fetch!(payload, "job_id")
end
