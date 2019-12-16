defmodule Meadow.Ingest.Notifications do
  @moduledoc """
  functions for notifications to absinthe subscriptions
  """
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Ingest.Sheets

  def send_ingest_sheet_notification({:ok, sheet}),
    do: {:ok, send_ingest_sheet_notification(sheet)}

  def send_ingest_sheet_notification(%Sheet{} = sheet) do
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

    sheet
  end

  def send_ingest_sheet_notification(other), do: other

  def send_ingest_sheet_row_notification({:ok, row}),
    do: {:ok, send_ingest_sheet_row_notification(row)}

  def send_ingest_sheet_row_notification(%Row{} = row) do
    topic = Enum.join(["row", row.sheet_id, row.state], ":")

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      row,
      ingest_sheet_row_state_update: topic
    )

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      row,
      ingest_sheet_row_update: Enum.join(["row", row.sheet_id], ":")
    )

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      Sheets.get_sheet_progress(row.sheet_id),
      ingest_sheet_progress_update: Enum.join(["progress", row.sheet_id], ":")
    )

    row
  end

  def send_ingest_sheet_row_notification(other), do: other
end
