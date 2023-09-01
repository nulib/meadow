defmodule MeadowWeb.Schema.HelperTypes do
  @moduledoc """
  Absinthe Schema for Random Queries
  """

  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :helper_queries do
    @desc "Get iiif server endpoint"
    field :iiif_server_url, :url do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Helpers.iiif_server_url/3)
    end

    @desc "Get digital collections endpoint"
    field :digital_collections_url, :url do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Helpers.digital_collections_url/3)
    end

    @desc "Get DCAPI endpoint"
    field :dcapi_endpoint, :url do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Helpers.dcapi_endpoint/3)
    end

    @desc "Get a presigned url to upload a file"
    field :presigned_url, :url do
      arg(:upload_type, non_null(:s3_upload_type))
      arg(:filename, :string)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Helpers.get_presigned_url/3)
    end

    @desc "Get a signed superuser DC API token"
    field :dc_api_token, :api_token do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Helpers.get_dc_api_token/3)
    end

    @desc "Get work archiver endpoint"
    field :work_archiver_endpoint, :url do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Helpers.work_archiver_endpoint/3)
    end
  end

  enum :s3_upload_type do
    value(:preservation_check,
      as: "preservation_check",
      description: "Preservation check download (.csv)"
    )

    value(:ingest_sheet, as: "ingest_sheet", description: "Ingest Sheet (.csv)")
    value(:file_set, as: "file_set", description: "File Set")
    value(:csv_metadata, as: "csv_metadata", description: "Metadata Update Sheet (.csv)")
  end
end
