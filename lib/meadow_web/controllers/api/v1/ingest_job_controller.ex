defmodule MeadowWeb.Api.V1.IngestJobController do
  use MeadowWeb, :controller

  alias Meadow.Ingest
  alias Meadow.Ingest.{Bucket, IngestJob}

  action_fallback MeadowWeb.FallbackController

  def index(conn, _params) do
    ingest_jobs = Ingest.list_ingest_jobs()
    render(conn, "index.json", ingest_jobs: ingest_jobs)
  end

  def create(conn, %{"ingest_job" => job_params}) do
    with {:ok, %IngestJob{} = ingest_job} <- Ingest.create_ingest_job(job_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.v1_ingest_job_path(conn, :show, ingest_job))
      |> render("show.json", ingest_job: ingest_job)
    end
  end

  def show(conn, %{"id" => id}) do
    ingest_job = Ingest.get_ingest_job!(id)
    render(conn, "show.json", ingest_job: ingest_job)
  end

  def update(conn, %{"id" => id, "ingest_job" => job_params}) do
    ingest_job = Ingest.get_ingest_job!(id)

    with {:ok, %IngestJob{} = ingest_job} <- Ingest.update_ingest_job(ingest_job, job_params) do
      render(conn, "show.json", ingest_job: ingest_job)
    end
  end

  def delete(conn, %{"id" => id}) do
    job = Ingest.get_ingest_job!(id)

    with {:ok, %IngestJob{}} <- Ingest.delete_ingest_job(job) do
      send_resp(conn, :no_content, "")
    end
  end

  def presigned_url(conn, _params) do
    url = Bucket.presigned_s3_url(Application.get_env(:meadow, :upload_bucket))

    render(conn, "presigned_url.json", url: url)
  end
end
