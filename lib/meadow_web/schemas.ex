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

  defmodule IngestJob do
    @moduledoc """
    Definition of OpenApiSpec Schema for Project

    """
    OpenApiSpex.schema(%{
      title: "IngestJob",
      description: "An ingest job that kicks off an inventory sheet upload",
      type: :object,
      properties: %{
        id: %Schema{type: :string, description: "Ingest Job ID", format: "ulid", readOnly: "true"},
        name: %Schema{type: :string, description: "Ingest Job Name", minLength: 4, maxLength: 140},
        filename: %Schema{type: :string, description: "Inventory Sheet Filename in S3 bucket"},
        presigned_url: %Schema{type: :string, description: "S3 csv upload url", format: :uri},
        project_id: %Schema{
          type: :string,
          description: "ID of the parent project",
          format: "ulid"
        },
        inserted_at: %Schema{
          type: :string,
          description: "Creation timestamp",
          format: :datetime
        },
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :datetime}
      },
      required: [:name, :presigned_url, :project_id, :filename],
      example: %{
        "id" => "01DEMM44VWN8M3PJFY4J5JJJMF",
        "name" => "Name of the Ingest Job",
        "project_id" => "01DFBXCA303G43Y3695NMQDH8F",
        "filename" => "01DFBXCA303G43Y3695NMQ1111.csv",
        "presigned_url" =>
          "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f005b504294c1bec6727a789"
      },
      "x-struct": __MODULE__
    })
  end

  defmodule IngestJobResponse do
    @moduledoc """
    Definition of OpenApiSpec Schema for an IngestJobResponse

    """
    OpenApiSpex.schema(%{
      title: "IngestJobResponse",
      description: "Response schema for single ingest job",
      type: :object,
      properties: %{
        data: IngestJob
      },
      example: %{
        "id" => "01DEMM44VWN8M3PJFY4J5JJJMF",
        "name" => "Name of the Ingest Job",
        "project_id" => "01DFBXCA303G43Y3695NMQDH8F",
        "filename" => "01DFBXCA303G43Y3695NMQ1111.csv",
        "presigned_url" =>
          "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f005b504294c1bec6727a789"
      },
      "x-struct": __MODULE__
    })
  end

  defmodule IngestJobsResponse do
    @moduledoc """
    Definition of OpenApiSpec Schema for IngestJobsResponse

    """
    OpenApiSpex.schema(%{
      title: "IngestJobsResponse",
      description: "Response schema for multiple ingest jobs",
      type: :object,
      properties: %{
        data: %Schema{description: "The ingest job details", type: :array, items: IngestJob}
      },
      example: %{
        "data" => [
          %{
            "id" => "01DEMM44VWN8M3PJFY4J5JJJMF",
            "name" => "Name of the Ingest Job",
            "project_id" => "01DFBXCA303G43Y3695NMQDH8F",
            "filename" => "01DFBXCA303G43Y3695NMQ1111.csv",
            "presigned_url" =>
              "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f005b504294c1bec6727a789"
          },
          %{
            "id" => "01DFBXN0BNB8YEPXCMCNGAWV2J",
            "name" => "Another Name of the Ingest Job",
            "project_id" => "01DFBXPN3EEZSWC6QTCFYQHTBB",
            "filename" => "01DFBXCA303G43Y3695NMQ1111.csv",
            "presigned_url" =>
              "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f0yyyy4294c1bec6727a789"
          }
        ]
      }
    })
  end

  defmodule IngestJobRequest do
    @moduledoc """
    Definition of OpenApiSpec Schema for ProjectRequest

    """
    OpenApiSpex.schema(%{
      title: "IngestJobRequest",
      description: "POST body for creating an ingest job",
      type: :object,
      properties: %{
        ingest_job: IngestJob
      },
      required: [:ingest_job],
      example: %{
        "ingest_job" => %{
          "name" => "The Name of the Ingest Job",
          "filename" => "01DFBXCA303G43Y3695NMQ1111.csv",
          "project_id" => "01DFBXPN3EEZSWC6QTCFYQHTBB",
          "presigned_url" =>
            "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f0yyyy4294c1bec6727a789"
        }
      },
      "x-struct": __MODULE__
    })
  end

  defmodule PresignedUrl do
    @moduledoc """
    Definition of OpenApiSpec Schema for PresignedUrl

    """
    OpenApiSpex.schema(%{
      title: "PresignedUrl",
      description: "A presigned S3 url to use for upload",
      type: :object,
      properties: %{
        url: %Schema{type: :string, description: "A presigned S3 url", format: "uri"}
      },
      required: [:url],
      example: %{
        "url" =>
          "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f0yyyy4294c1bec6727a789"
      },
      "x-struct": __MODULE__
    })
  end

  defmodule PresignedUrlResponse do
    @moduledoc """
    Definition of OpenApiSpec Schema for an IngestJobResponse

    """
    OpenApiSpex.schema(%{
      title: "PresignedUrlResponse",
      description: "Response schema for presigned url to upload to S3",
      type: :object,
      properties: %{
        data: PresignedUrl
      },
      example: %{
        "url" =>
          "http://localhost:9001/dev-uploads/inventory_sheets/01DFENBFNJAMYKR3C9YT3NRVWZ.csv?contentType=binary%2Foctet-stream&x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20190710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190710T192152Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=a215cd85011af1cd54bxxxxx8ad67a1de83bf5b0f0yyyy4294c1bec6727a789"
      },
      "x-struct": __MODULE__
    })
  end
end
