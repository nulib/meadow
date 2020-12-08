defmodule Meadow.BatchNotifier do
  @moduledoc """
  Listens for and handles notifications about updates to batches table
  """
  use Meadow.DatabaseNotification, tables: [:batches]

  alias Meadow.Batches
  alias Meadow.Notifications

  @impl true
  def handle_notification(:batches, :delete, _key, state), do: {:noreply, state}

  def handle_notification(:batches, _op, %{id: id}, state) do
    batch = Batches.get_batch!(id)
    Notifications.batch(batch)
    {:noreply, state}
  end
end
