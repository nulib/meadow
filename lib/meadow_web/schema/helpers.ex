defmodule MeadowWeb.Schema.Helpers do
  @moduledoc """
  Helper methods for GraphQL schema
  """
  alias Meadow.Ingest.IngestJobs

  def job_progress(_, ids) do
    IngestJobs.get_job_progress(ids)
  end
end
