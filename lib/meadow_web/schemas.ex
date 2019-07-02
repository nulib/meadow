defmodule MeadowWeb.Schemas do
  @moduledoc """
  Definition of OpenApiSpec Schemas

  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule Project do
    @moduledoc """
    Definition of OpenApiSpec Schema for Project

    """
    OpenApiSpex.schema(%{
      title: "Project",
      description: "An Ingest Project",
      type: :object,
      properties: %{
        id: %Schema{type: :string, description: "Project ID", format: "ulid", readOnly: "true"},
        title: %Schema{type: :string, description: "Project Title", minLength: 4, maxLength: 140},
        folder: %Schema{type: :string, description: "s3 Folder", readOnly: "true"},
        inserted_at: %Schema{
          type: :string,
          description: "Creation timestamp",
          format: :datetime
        },
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :datetime}
      },
      required: [:title],
      example: %{
        "id" => "01DEMM44VWN8M3PJFY4J5JJJMF",
        "title" => "Sample Ingest Project",
        "folder" => "sample-ingest-project-1561914496"
      },
      "x-struct": __MODULE__
    })
  end

  defmodule ProjectRequest do
    @moduledoc """
    Definition of OpenApiSpec Schema for ProjectRequest

    """
    OpenApiSpex.schema(%{
      title: "ProjectRequest",
      description: "POST body for creating a project",
      type: :object,
      properties: %{
        project: Project
      },
      required: [:project],
      example: %{
        "project" => %{
          "title" => "The Name of the Project"
        }
      },
      "x-struct": __MODULE__
    })
  end

  defmodule ProjectResponse do
    @moduledoc """
    Definition of OpenApiSpec Schema for a ProjectResponse

    """
    OpenApiSpex.schema(%{
      title: "ProjectResponse",
      description: "Response schema for single project",
      type: :object,
      properties: %{
        data: Project
      },
      example: %{
        "data" => %{
          "id" => "01DEMM44VWN8M3PJFY4J5JJJMF",
          "title" => "Sample Project",
          "folder" => "sample-project-1561914427"
        }
      },
      "x-struct": __MODULE__
    })
  end

  defmodule ProjectsResponse do
    @moduledoc """
    Definition of OpenApiSpec Schema for a ProjectResponse

    """
    OpenApiSpex.schema(%{
      title: "ProjectsResponse",
      description: "Response schema for multiple projects",
      type: :object,
      properties: %{
        data: %Schema{description: "The projects details", type: :array, items: Project}
      },
      example: %{
        "data" => [
          %{
            "id" => "01DEMM44VWN8M3PJFY4J5JJJMF",
            "title" => "Sample Project",
            "folder" => "sample-project-1561914427"
          },
          %{
            "id" => "01DEMHYCAS4XKY0685F40GF8XT",
            "title" => "Another Sample Project",
            "folder" => "another-sample-project-1561914398"
          }
        ]
      }
    })
  end
end
