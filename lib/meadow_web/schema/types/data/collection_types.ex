defmodule MeadowWeb.Schema.Data.CollectionTypes do
  @moduledoc """
  Absinthe Schema for CollectionTypes

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

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
      arg(:title, non_null(:string))
      arg(:description, :string)
      arg(:keywords, list_of(:string))
      arg(:admin_email, :string)
      arg(:finding_aid_url, :string)
      arg(:featured, :boolean)
      arg(:published, :boolean)
      arg(:visibility, :coded_term_input)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.Data.Collections.create_collection/3)
    end

    @desc "Update a Collection"
    field :update_collection, :collection do
      arg(:collection_id, non_null(:id))
      arg(:title, :string)
      arg(:description, :string)
      arg(:keywords, list_of(:string))
      arg(:admin_email, :string)
      arg(:finding_aid_url, :string)
      arg(:featured, :boolean)
      arg(:published, :boolean)
      arg(:visibility, :coded_term_input)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.Data.Collections.update_collection/3)
    end

    @desc "Add Works to a Collection"
    field :add_works_to_collection, :collection do
      arg(:collection_id, non_null(:id))
      arg(:work_ids, list_of(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.Collections.add_works/3)
    end

    @desc "Remove Works from a Collection"
    field :remove_works_from_collection, :collection do
      arg(:collection_id, non_null(:id))
      arg(:work_ids, list_of(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.Collections.remove_works/3)
    end

    @desc "Set the representative Work for a Collection"
    field :set_collection_image, :collection do
      arg(:collection_id, non_null(:id))
      arg(:work_id, :id)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.Data.Collections.set_collection_image/3)
    end

    @desc "Delete a Collection"
    field :delete_collection, :collection do
      arg(:collection_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.Data.Collections.delete_collection/3)
    end
  end

  #
  # Object Types
  #

  @desc "Fields for a `collection` object "
  object :collection do
    field :id, :id
    field :title, :string
    field :description, :string
    field :keywords, list_of(:string)
    field :featured, :boolean
    field :admin_email, :string
    field :finding_aid_url, :string
    field :published, :boolean
    field :works, list_of(:work), resolve: &Resolvers.Data.Collections.collection_works/3
    field :visibility, :coded_term

    field :representative_image, :string do
      deprecate("Use  `representativeWork`.")
    end

    field :representative_work, :work

    field :total_works, :integer,
      resolve: fn query, _, _ ->
        Meadow.Data.Collections.get_work_count(query.id)
      end
  end
end
