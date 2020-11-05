defmodule Meadow.Ingest.Notifications do
  @moduledoc """
  functions for notifications to absinthe subscriptions
  """
  alias Meadow.Ingest.Schemas.Sheet
  require Logger

  def ingest_sheet({:ok, sheet}),
    do: {:ok, ingest_sheet(sheet)}

  def ingest_sheet(%Sheet{} = sheet) do
    Logger.info(
      "Sending notifications for ingest sheet: #{sheet.id}, in project: #{sheet.project_id} with status: #{
        sheet.status
      }"
    )

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

  def ingest_sheet(other), do: other
end
