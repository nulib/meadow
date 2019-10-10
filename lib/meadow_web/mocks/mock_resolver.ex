defmodule MeadowWeb.Resolvers.Mock do
  @moduledoc """
  Absinthe GraphQL query resolver for Ingest Context

  """
  alias Meadow.Ingest.{IngestSheets, MockSubscription}
  alias MeadowWeb.Schema.ChangesetErrors

  def mock_approve_ingest_sheet(_, %{id: id}, _) do
    ingest_sheet = IngestSheets.get_ingest_sheet!(id)

    case IngestSheets.update_ingest_sheet_status(ingest_sheet, "approved") do
      {:error, changeset} ->
        {
          :error,
          message: "Could not approve sheet", details: ChangesetErrors.error_details(changeset)
        }

      {:ok, ingest_sheet} ->
        MockSubscription.async(ingest_sheet.id)
        {:ok, ingest_sheet}
    end
  end
end
