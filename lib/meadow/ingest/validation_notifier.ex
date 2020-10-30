defmodule Meadow.Ingest.ValidationNotifier do
  @moduledoc """
  BackgroundTask to send periodic notifications about ingest sheet validation status
  """

  alias Meadow.BackgroundTask
  alias Meadow.Ingest.{Notifications, Sheets}
  import Meadow.Utils.Logging

  use BackgroundTask, function: :send_validation_notifications, default_interval: 1_000

  def send_validation_notifications(state) do
    with_log_level(:info, fn ->
      Sheets.list_ingest_sheets_by_status(:uploaded)
      |> Enum.each(fn sheet ->
        Notifications.ingest_sheet_validation(sheet)
      end)
    end)

    {:noreply, state}
  end
end
