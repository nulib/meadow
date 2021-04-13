defmodule Meadow.Ingest.Notifications do
  @moduledoc """
  functions for notifications to absinthe subscriptions
  """
  use Meadow.Utils.Logging

  alias Meadow.Ingest.Schemas.Sheet
  require Logger

  def ingest_sheet({:ok, sheet}),
    do: {:ok, ingest_sheet(sheet)}

  def ingest_sheet(%Sheet{} = sheet) do
    with_log_metadata module: __MODULE__, id: sheet.id do
      ("Sending notifications for ingest sheet: #{sheet.id} " <>
         "in project: #{sheet.project_id} with status: #{sheet.status}")
      |> Logger.info()

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
  end

  def ingest_sheet(other), do: other
end
