defmodule MeadowWeb.Schema.Helpers do
  @moduledoc """
  Helper methods for GraphQL schema
  """
  def job_progress(_, ids) do
    Meadow.Ingest.IngestJobs.get_job_progress(ids)
  end
end
