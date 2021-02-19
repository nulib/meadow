defmodule MeadowWeb.Schema.Helpers do
  @moduledoc """
  Helper methods for GraphQL schema
  """
  alias Meadow.Ingest.Sheets

  def validation_progress(_, ids) do
    Sheets.get_sheet_validation_progress(ids)
  end
end
