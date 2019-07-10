defmodule MeadowWeb.Api.V1.ProjectController do
  use MeadowWeb, :controller

  alias Meadow.Ingest
  alias Meadow.Ingest.Project
  alias MeadowWeb.Schemas
  import OpenApiSpex.Operation
  alias OpenApiSpex.Operation

  action_fallback MeadowWeb.FallbackController

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def index_operation do
    %Operation{
      tags: ["projects"],
      summary: "List projects",
      description: "List all projects",
      operationId: "ProjectController.index",
      responses: %{
        200 => response("Project List Response", "application/json", Schemas.ProjectsResponse)
      }
    }
  end

  def index(conn, _params) do
    projects = Ingest.list_projects()
    render(conn, "index.json", projects: projects)
  end

  def create_operation do
    %Operation{
      tags: ["projects"],
      summary: "Create project",
      description: "Create a project",
      operationId: "ProjectController.create",
      requestBody:
        request_body("The project attributes", "application/json", Schemas.ProjectRequest,
          required: true
        ),
      responses: %{
        201 => response("Project", "application/json", Schemas.ProjectResponse)
      }
    }
  end

  def create(conn, %{"project" => project_params}) do
    with {:ok, %Project{} = project} <- Ingest.create_project(project_params) do
      Application.get_env(:meadow, :ingest_bucket)
      |> Meadow.Ingest.Bucket.create_project_folder(project.folder)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.v1_project_path(conn, :show, project))
      |> render("show.json", project: project)
    end
  end

  def show_operation do
    %Operation{
      tags: ["projects"],
      summary: "Show project",
      description: "Show a project by ID",
      operationId: "ProjectController.show",
      parameters: [
        Operation.parameter(:id, :path, :string, "Project ID",
          example: "01DEMRE5KZM6GCWVNGB0A2ZDN8"
        )
      ],
      responses: %{
        200 => Operation.response("Project", "application/json", Schemas.ProjectResponse)
      }
    }
  end

  def show(conn, %{"id" => id}) do
    project = Ingest.get_project!(id)
    render(conn, "show.json", project: project)
  end

  def update_operation do
    %Operation{
      tags: ["projects"],
      summary: "Update project",
      description: "Update a project",
      operationId: "ProjectController.update",
      parameters: [
        Operation.parameter(:id, :path, :string, "Project ID",
          example: "01DEHZZ8B9TNWZN7M1FXDP5NZB"
        )
      ],
      requestBody:
        request_body("The project attributes", "application/json", Schemas.ProjectRequest,
          required: true
        ),
      responses: %{
        201 => response("Project", "application/json", Schemas.ProjectResponse)
      }
    }
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Ingest.get_project!(id)

    with {:ok, %Project{} = project} <- Ingest.update_project(project, project_params) do
      render(conn, "show.json", project: project)
    end
  end

  def delete_operation do
    %Operation{
      tags: ["projects"],
      summary: "Delete project",
      description: "Delete a project by ID",
      operationId: "ProjectController.delete",
      parameters: [
        Operation.parameter(:id, :path, :string, "Project ID",
          example: "01DEHZZ8B9TNWZN7M1FXDP5NZB"
        )
      ],
      responses: %{
        200 => Operation.response("Project", "application/json", Schemas.ProjectResponse)
      }
    }
  end

  def delete(conn, %{"id" => id}) do
    project = Ingest.get_project!(id)

    with {:ok, %Project{}} <- Ingest.delete_project(project) do
      send_resp(conn, :no_content, "")
    end
  end
end
