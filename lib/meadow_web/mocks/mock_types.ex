defmodule MeadowWeb.Schema.MockTypes do
  @moduledoc """
  Absinthe Schema for WorkTypes

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
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

  @errors_db %{
    "foo" => %{
      file_sets: [
        %{
          row_number: 1,
          accession_number: "Something_Else_003_001",
          work_accession_number: "Something_Else_003",
          role: "am",
          description: "Mauris pellentesque sodales",
          filename: "s3://the/path/to/the/file.tif",
          errors: ["Duplicate accession number"]
        },
        %{
          row_number: 2,
          accession_number: "Something_Else_003_002",
          work_accession_number: "Something_Else_003",
          role: "am",
          description: "Mauris pellentesque sodales",
          filename: "s3://the/path/to/the/file.tif",
          errors: ["Couldn't find file: s3://the/path/to/the/file.tif"]
        },
        %{
          row_number: 8,
          accession_number: "Something_Else_004_001",
          work_accession_number: "Something_Else_004",
          role: "am",
          description: "Mauris pellentesque sodales",
          filename: "s3://the/path/to/the/file.tif",
          errors: ["Problem creating pyramidal tif", "Duplicate work accession number"]
        },
        %{
          row_number: 9,
          accession_number: "Something_Else_004_002",
          work_accession_number: "Something_Else_004",
          role: "am",
          description: "Mauris pellentesque sodales",
          filename: "s3://the/path/to/the/file.tif",
          errors: ["Error moving file to preservation storage", "Duplicate work accession number"]
        },
        %{
          row_number: 10,
          accession_number: "Something_Else_004_002",
          work_accession_number: "Something_Else_004",
          role: "am",
          description: "Mauris pellentesque sodales",
          filename: "s3://the/path/to/the/file.tif",
          errors: ["Duplicate accession number", "Duplicate work accession number"]
        }
      ]
    }
  }

  object :mock_queries do
    @desc "`MOCK` for getting (successfully) created works for a completed IngestSheet"
    field :mock_ingest_sheet, :mock_ingest_sheet do
      @desc "The ID of `IngestSheet` (can be anything)"
      arg(:id, type: non_null(:id))
      middleware(Middleware.Authenticate)

      resolve(fn %{id: _id}, _ ->
        {:ok, Map.get(@fake_db, "foo")}
      end)
    end

    @desc "`MOCK` for getting errors for completed ingest sheet"
    field :mock_ingest_sheet_errors, :mock_ingest_sheet_errors do
      @desc "The ID of `IngestSheet` (can be anything)"
      arg(:id, type: non_null(:id))
      middleware(Middleware.Authenticate)

      resolve(fn %{id: _id}, _ ->
        {:ok, Map.get(@errors_db, "foo")}
      end)
    end
  end

  object :mock_mutations do
    @desc "MOCK Approve an Ingest Sheet"
    field :mock_approve_ingest_sheet, :ingest_sheet do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Mock.mock_approve_ingest_sheet/3)
    end
  end

  object :mock_subscriptions do
    @desc "MOCK for subscription of count of works created during ingest progress"
    field :mock_works_created_count, :mock_count do
      arg(:sheet_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: Enum.join(["mock_subscription", args.sheet_id], ":")}
      end)
    end
  end

  object :mock_count do
    field :count, :integer
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

  @desc "MOCK ingest errors for each row (file_set)"
  object :mock_ingest_sheet_errors do
    field :file_sets, list_of(:mock_row_errors)
  end

  @desc "MOCK file_set (row) errors"
  object :mock_row_errors do
    field :row_number, :integer
    field :accession_number, :string
    field :work_accession_number, :string
    field :role, :string
    field :description, :string
    field :filename, :string
    field :errors, list_of(:string)
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
