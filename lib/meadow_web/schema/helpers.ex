defmodule MeadowWeb.Schema.Helpers do
  @moduledoc """
  Helper methods for GraphQL schema
  """
  alias Meadow.Ingest.Sheets

  def sheet_progress(_, ids) do
    Sheets.get_sheet_progress(ids)
  end
end
