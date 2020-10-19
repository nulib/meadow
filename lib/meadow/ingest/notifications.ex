defmodule Meadow.Ingest.Notifications do
  @moduledoc """
  functions for notifications to absinthe subscriptions
  """
  alias Meadow.Ingest.Schemas.Sheet
  alias Meadow.Ingest.Sheets

  def ingest_sheet({:ok, sheet}),
    do: {:ok, ingest_sheet(sheet)}

  def ingest_sheet(%Sheet{} = sheet) do
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

  def ingest_sheet_validation(%Sheet{} = sheet) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      Sheets.get_sheet_validation_progress(sheet.id),
      ingest_sheet_validation_progress: Enum.join(["validation_progress", sheet.id], ":")
    )

    sheet
  end

  def ingest_sheet_validation(other), do: other
end
