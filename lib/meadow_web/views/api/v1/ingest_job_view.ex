defmodule MeadowWeb.Api.V1.IngestJobView do
  use MeadowWeb, :view
  alias MeadowWeb.Api.V1.IngestJobView

  def render("index.json", %{ingest_jobs: ingest_jobs}) do
    %{data: render_many(ingest_jobs, IngestJobView, "ingest_job.json")}
  end

  def render("show.json", %{ingest_job: ingest_job}) do
    %{data: render_one(ingest_job, IngestJobView, "ingest_job.json")}
  end

  def render("ingest_job.json", %{ingest_job: ingest_job}) do
    %{
      id: ingest_job.id,
      name: ingest_job.name,
      filename: ingest_job.filename,
      presigned_url: ingest_job.presigned_url,
      project_id: ingest_job.project_id,
      inserted_at: ingest_job.inserted_at,
      updated_at: ingest_job.updated_at
    }
  end

  def render("presigned_url.json", %{url: url}) do
    %{
      data: %{presigned_url: url}
    }
  end
end
