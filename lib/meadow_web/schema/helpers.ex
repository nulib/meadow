defmodule MeadowWeb.Schema.Helpers do
  @moduledoc """
  Helper methods for GraphQL schema
  """
  alias Meadow.Ingest.IngestSheets

  def sheet_progress(_, ids) do
    IngestSheets.get_sheet_progress(ids)
  end
end
