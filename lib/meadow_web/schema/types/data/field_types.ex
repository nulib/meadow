defmodule MeadowWeb.Schema.Data.FieldTypes do
  @moduledoc """
  Absinthe Schema for field (metadata properties) queries

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :field_queries do
    @desc "Describes the metadata properties on works"
    field :describe_fields, list_of(:field_info) do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Fields.describe/3)
    end

    field :describe_field, :field_info do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Fields.describe/3)
    end
  end

  object :field_info do
    field :id, :string
    field :label, :string
    field :metadata_class, :string
    field :repeating, :boolean
    field :required, :boolean
    field :role, :code_list_scheme
    field :scheme, :code_list_scheme
  end
end
