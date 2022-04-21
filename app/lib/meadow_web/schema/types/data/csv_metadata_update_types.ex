defmodule MeadowWeb.Schema.Data.CSVMetadataUpdateTypes do
  @moduledoc """
  Absinthe Schema for CSV Metadata Update Functionality

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data.CSV.MetadataUpdateJobs
  alias MeadowWeb.Schema.Middleware

  object :csv_metadata_update_queries do
    @desc "Get all metadata update jobs"
    field :csv_metadata_update_jobs, list_of(:csv_metadata_update_job) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&MetadataUpdateJobs.list_jobs/3)
    end

    @desc "Get a metadata update job by id"
    field :csv_metadata_update_job, :csv_metadata_update_job do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&MetadataUpdateJobs.get_job/3)
    end
  end

  object :csv_metadata_update_mutations do
    @desc "Start a CSV metadata update operation"
    field :csv_metadata_update, :csv_metadata_update_job do
      arg(:filename, non_null(:string))
      arg(:source, non_null(:string))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&MetadataUpdateJobs.update/3)
    end
  end

  #
  # Object Types
  #

  @desc "Fields for a `metadata_update_job` object"
  object :csv_metadata_update_job do
    field :id, :id
    field :filename, :string
    field :source, :string
    field :rows, :integer
    field :errors, list_of(:row_errors)
    field :status, :string
    field :inserted_at, :datetime
    field :started_at, :datetime
    field :updated_at, :datetime
    field :user, :string
  end

  @desc "Row-based errors for a `metadata_update_job`"
  object :row_errors do
    field :row, :integer
    field :errors, list_of(:errors)
  end
end
