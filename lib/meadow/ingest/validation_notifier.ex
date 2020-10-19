defmodule Meadow.Ingest.ValidationNotifier do
  @moduledoc """
  IntervalTask to send periodic notifications about ingest sheet validation status
  """

  alias Meadow.Ingest.{Notifications, Sheets}
  alias Meadow.IntervalTask
  import Meadow.Utils.Logging

  use IntervalTask, function: :send_validation_notifications, default_interval: 1_000

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
