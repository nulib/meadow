defmodule Meadow.Ingest.SheetNotifier do
  @moduledoc """
  Listens for and handles notifications about updates to ingest_sheets table
  """
  use Meadow.DatabaseNotification, tables: [:ingest_sheets]
  require Logger

  alias Meadow.Ingest.Notifications
  alias Meadow.Ingest.Sheets

  @impl true
  def handle_notification(:ingest_sheets, :delete, _key, state), do: {:noreply, state}

  def handle_notification(:ingest_sheets, _op, %{id: id}, state) do
    sheet = Sheets.get_ingest_sheet!(id)
    Logger.info("Sending notification for ingest sheet: #{id} with status: #{sheet.status}")
    Notifications.ingest_sheet(sheet)
    {:noreply, state}
  end
end
