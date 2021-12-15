defmodule Meadow.Ingest.SheetNotifier do
  @moduledoc """
  Listens for and handles notifications about updates to ingest_sheets table
  """
  use Meadow.DatabaseNotification, tables: [:ingest_sheets]

  alias Meadow.Ingest.Notifications
  alias Meadow.Ingest.Sheets

  @impl true
  def handle_notification(:ingest_sheets, :delete, _key, state), do: {:noreply, state}

  def handle_notification(:ingest_sheets, _op, %{id: id}, state) do
    sheet = Sheets.get_ingest_sheet!(id)
    Notifications.ingest_sheet(sheet)
    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end

  def handle_notification(_, _, _, state), do: {:noreply, state}
end
