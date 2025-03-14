defmodule Meadow.Events.IngestSheets.SheetUpdates do
  @moduledoc """
  Handles events related to updating ingest sheets
  """

  alias Meadow.Ingest.Sheets

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  require Logger

  on_event(:ingest_sheets, %{}, [{__MODULE__, :handle_notification}], & &1)

  def handle_notification(%{name: name, new_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      Logger.info("Sending notifications for ingest sheet: #{record.id}")
      sheet = Sheets.get_ingest_sheet!(record.id)

      Absinthe.Subscription.publish(
        MeadowWeb.Endpoint,
        sheet,
        ingest_sheet_update: "sheet:" <> sheet.id
      )

      Absinthe.Subscription.publish(
        MeadowWeb.Endpoint,
        sheet,
        ingest_sheet_updates_for_project: "sheets:" <> sheet.project_id
      )
    end
  rescue
    Ecto.NoResultsError -> :noop
  end
end
