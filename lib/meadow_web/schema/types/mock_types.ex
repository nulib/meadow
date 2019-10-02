defmodule MeadowWeb.Schema.MockTypes do
  @moduledoc """
  Absinthe Schema for WorkTypes

  """
  use Absinthe.Schema.Notation

  alias MeadowWeb.Schema.Middleware

  @fake_db %{
    "foo" => %{
      id: "01DP6073MBNW6K85GS9J805DCE",
      name: "Sample Ingest Sheet",
      filename: "something.csv",
      status: "completed",
      works: [
        %{
          id: "01DP6073MBNW6K85GS9J805DJJ",
          accession_number: "Something_001",
          visibility: "open",
          work_type: "image",
          file_sets: [
            %{
              id: "01DP6073MBNW6K85GS9J805D66",
              accession_number: "Something_001_01",
              role: "am",
              metadata: %{
                description: "Mauris pellentesque sodales"
              }
            },
            %{
              id: "01DP6073MBNW6K85GS9J805DLL",
              accession_number: "Something_001_02",
              role: "am",
              metadata: %{
                description: "Mauris pellentesque sodales"
              }
            },
            %{
              id: "01DP6073MBNW6K85GS9J805DLL",
              accession_number: "Something_001_03",
              role: "am",
              metadata: %{
                description: "Mauris pellentesque sodales"
              }
            }
          ]
        },
        %{
          id: "01DP6073MBNW6K85GS9J805DDJJ",
          accession_number: "Something_Else_002",
          visibility: "open",
          work_type: "image",
          file_sets: [
            %{
              id: "01DP6073MBNW6K85GS9J805D66",
              accession_number: "Something_Else_002_01",
              role: "am",
              metadata: %{
                description: "Mauris pellentesque sodales"
              }
            },
            %{
              id: "01DP6073MBNW6K85GS9J805DLL",
              accession_number: "Something_Else_002_02",
              role: "am",
              metadata: %{
                description: "Mauris pellentesque sodales"
              }
            },
            %{
              id: "01DP6073MBNW6K85GS9J805DLL",
              accession_number: "Something_Else_002_03",
              role: "am",
              metadata: %{
                description: "Mauris pellentesque sodales"
              }
            }
          ]
        }
      ]
    }
  }

  object :mock_queries do
    @desc "`MOCK` for getting completed works along with an IngestSheet"
    field :mock_ingest_sheet, list_of(:mock_ingest_sheet) do
      @desc "The ID of `IngestSheet`"
      arg(:id, type: non_null(:id))
      middleware(Middleware.Authenticate)

      resolve(fn %{id: _id}, _ ->
        {:ok, Map.get(@fake_db, "foo")}
      end)
    end
  end

  @desc "MOCK IngestSheet object"
  object :mock_ingest_sheet do
    field :id, non_null(:id)
    field :name, non_null(:string)
    @desc "Overall Status of the Ingest Sheet"
    field :status, :ingest_sheet_status
    field :filename, non_null(:string)
    field :works, list_of(:mock_work)
  end

  @desc "MOCK work object"
  object :mock_work do
    field :id, non_null(:id)
    field :accession_number, non_null(:string)
    field :work_type, non_null(:work_type)
    field :visibility, non_null(:visibility)

    field :file_sets, list_of(:mock_file_set)
  end

  @desc "MOCK `file_set` object represents one file (repository object in S3)"
  object :mock_file_set do
    field :id, non_null(:id)
    field :accession_number, non_null(:string)
    field :role, non_null(:file_set_role)
    field :metadata, :mock_file_set_metadata
  end

  @desc "MOCK `file_set_metadata` represents all metadata associated with a file set object. It is stored in a single json field."
  object :mock_file_set_metadata do
    field :location, :string
    field :original_filename, :string
    field :description, :string
  end
end
