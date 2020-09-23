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
  end
end
