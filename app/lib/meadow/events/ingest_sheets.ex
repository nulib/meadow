defmodule Meadow.Events.IngestSheets do
  @moduledoc """
  Handles IngestSheet events for publishing progress notifications.
  """

  use WalEx.Event, name: Meadow

  on_insert(:ingest_sheets, %{}, [{Meadow.Events.SheetUpdates, :handle_notification}], & &1)
  on_update(:ingest_sheets, %{}, [{Meadow.Events.SheetUpdates, :handle_notification}], & &1)
end
