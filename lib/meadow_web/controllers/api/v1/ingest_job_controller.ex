defmodule MeadowWeb.Api.V1.IngestJobController do
  use MeadowWeb, :controller

  alias Meadow.Ingest
  alias Meadow.Ingest.{Bucket, IngestJob}
  alias MeadowWeb.Schemas
  alias OpenApiSpex.Operation

  import OpenApiSpex.Operation

  action_fallback MeadowWeb.FallbackController

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def index_operation do
    %Operation{
      tags: ["ingest_jobs"],
      summary: "List Ingest Jobs",
      description: "List all ingest jobs",
      operationId: "IngestJobController.index",
      responses: %{
        200 => response("Project List Response", "application/json", Schemas.IngestJobsResponse)
      }
    }
  end

  def index(conn, _params) do
    ingest_jobs = Ingest.list_ingest_jobs()
    render(conn, "index.json", ingest_jobs: ingest_jobs)
  end

  def create_operation do
    %Operation{
      tags: ["ingest_jobs"],
      summary: "Create ingest job",
      description: "Create an ingest job",
      operationId: "IngestJobController.create",
      requestBody:
        request_body("The ingest job attributes", "application/json", Schemas.IngestJobRequest,
          required: true
        ),
      responses: %{
        201 => response("Ingest Job", "application/json", Schemas.IngestJobResponse)
      }
    }
  end

  def create(conn, %{"ingest_job" => job_params}) do
    with {:ok, %IngestJob{} = ingest_job} <- Ingest.create_ingest_job(job_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.v1_ingest_job_path(conn, :show, ingest_job))
      |> render("show.json", ingest_job: ingest_job)
    end
  end

  def show_operation do
    %Operation{
      tags: ["ingest_jobs"],
      summary: "Show ingest job",
      description: "Show a ingest job by ID",
      operationId: "IngestJobController.show",
      parameters: [
        Operation.parameter(:id, :path, :string, "Ingest Job ID",
          example: "01DEMRE5KZM6GCWVNGB0A2ZDN8"
        )
      ],
      responses: %{
        200 => Operation.response("Project", "application/json", Schemas.ProjectResponse)
      }
    }
  end

  def show(conn, %{"id" => id}) do
    ingest_job = Ingest.get_ingest_job!(id)
    render(conn, "show.json", ingest_job: ingest_job)
  end

  def update_operation do
    %Operation{
      tags: ["ingest_jobs"],
      summary: "Update an ingest job",
      description: "Update an ingest job",
      operationId: "IngestJobController.update",
      parameters: [
        Operation.parameter(:id, :path, :string, "Ingest Job ID",
          example: "01DEHZZ8B9TNWZN7M1FXDP5NZB"
        )
      ],
      requestBody:
        request_body("The ingest job attributes", "application/json", Schemas.IngestJobRequest,
          required: true
        ),
      responses: %{
        201 => response("Project", "application/json", Schemas.IngestJobResponse)
      }
    }
  end

  def update(conn, %{"id" => id, "ingest_job" => job_params}) do
    ingest_job = Ingest.get_ingest_job!(id)

    with {:ok, %IngestJob{} = ingest_job} <- Ingest.update_ingest_job(ingest_job, job_params) do
      render(conn, "show.json", ingest_job: ingest_job)
    end
  end

  def delete_operation do
    %Operation{
      tags: ["ingest_jobs"],
      summary: "Delete ingest job",
      description: "Delete an ingest job by ID",
      operationId: "IngestJobController.delete",
      parameters: [
        Operation.parameter(:id, :path, :string, "IngestJob ID",
          example: "01DEHZZ8B9TNWZN7M1FXDP5NZB"
        )
      ],
      responses: %{
        200 => Operation.response("IngestJob", "application/json", Schemas.IngestJobResponse)
      }
    }
  end

  def delete(conn, %{"id" => id}) do
    job = Ingest.get_ingest_job!(id)

    with {:ok, %IngestJob{}} <- Ingest.delete_ingest_job(job) do
      send_resp(conn, :no_content, "")
    end
  end

  def presigned_url_operation do
    %Operation{
      tags: ["ingest_jobs"],
      summary: "Get presigned s3 url for upload",
      description: "Get presigned s3 url for upload",
      operationId: "IngestJobController.presigned_url",
      responses: %{
        200 => Operation.response("Project", "application/json", Schemas.PresignedUrlResponse)
      }
    }
  end

  def presigned_url(conn, _params) do
    url = Bucket.presigned_s3_url(Application.get_env(:meadow, :upload_bucket))

    render(conn, "presigned_url.json", url: url)
  end
end
