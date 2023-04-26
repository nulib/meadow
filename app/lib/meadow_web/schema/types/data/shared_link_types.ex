defmodule MeadowWeb.Schema.Data.SharedLinkTypes do
  @moduledoc """
  GraphQL schema types for SharedLinks
  """

  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data
  alias MeadowWeb.Schema.Middleware

  object :shared_link_mutations do
    @desc "Create a temporary shared link (resolves to DC) for a work"
    field :create_shared_link, :shared_link do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Data.SharedLinks.generate/3)
    end
  end

  object :shared_link do
    field(:shared_link_id, non_null(:id))
    field(:work_id, non_null(:id))
    field(:expires, non_null(:datetime))
  end
end
