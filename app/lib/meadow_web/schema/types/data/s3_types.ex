defmodule MeadowWeb.Schema.Data.S3Types do
  @moduledoc """
  Absinthe Schema for S3Types

  """
  use Absinthe.Schema.Notation

  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :s3_queries do
    @desc "List ingest bucket objects"
    field :list_ingest_bucket_objects, list_of(:s3_object) do
      arg(:prefix, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.list_ingest_bucket_objects/3)
    end
  end

  object :s3_object do
    field(:owner, :s3_owner)
    field(:size, :string)
    field(:key, :string)
    field(:last_modified, :string)
    field(:storage_class, :string)
    field(:e_tag, :string)
    field(:mime_type, :string)
  end

  object :s3_owner do
    field(:id, :string)
    field(:display_name, :string)
  end
end
