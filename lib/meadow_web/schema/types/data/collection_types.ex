defmodule MeadowWeb.Schema.Data.CollectionTypes do
  @moduledoc """
  Absinthe Schema for CollectionTypes

  """
  use Absinthe.Schema.Notation
  alias Meadow.Data
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :collection_queries do
    @desc "Get a list of collections"
    field :collections, list_of(:collection) do
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.Collections.collections/3)
    end

    @desc "Get a collection by id"
    field :collection, :collection do
      arg(:collection_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.Collections.collection/3)
    end
  end

  object :collection_mutations do
    @desc "Create a new Collection"
    field :create_collection, :collection do
      arg(:name, non_null(:string))
      arg(:description, :string)
      arg(:keywords, list_of(:string))
      arg(:admin_email, :string)
      arg(:finding_aid_url, :string)
      arg(:featured, :boolean)
      arg(:published, :boolean)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.Collections.create_collection/3)
    end

    @desc "Update a Collection"
    field :update_collection, :collection do
      arg(:collection_id, non_null(:id))
      arg(:name, :string)
      arg(:description, :string)
      arg(:keywords, list_of(:string))
      arg(:admin_email, :string)
      arg(:finding_aid_url, :string)
      arg(:featured, :boolean)
      arg(:published, :boolean)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.Collections.update_collection/3)
    end

    @desc "Delete a Collection"
    field :delete_collection, :collection do
      arg(:collection_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.Collections.delete_collection/3)
    end
  end

  #
  # Object Types
  #

  @desc "Fields for a `collection` object "
  object :collection do
    field :id, :id
    field :name, :string
    field :description, :string
    field :keywords, list_of(:string)
    field :featured, :boolean
    field :admin_email, :string
    field :finding_aid_url, :string
    field :published, :boolean
    field :works, list_of(:work), resolve: dataloader(Data)
  end
end
