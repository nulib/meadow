defmodule MeadowWeb.Schema.Data.WorkTypes do
  @moduledoc """
  Absinthe Schema for WorkTypes

  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Meadow.Data
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :work_queries do
    @desc "Get a list of works"
    field :works, list_of(:work) do
      arg(:limit, :integer, default_value: 100)
      arg(:filter, :work_filter)
      arg(:order, type: :sort_order, default_value: :asc)
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.works/3)
    end

    @desc "Get a work by id"
    field :work, :work do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.work/3)
    end

    @desc "Get a work by accession_number"
    field :work_by_accession, :work do
      arg(:accession_number, non_null(:string))
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.work/3)
    end
  end

  object :work_mutations do
    @desc "Create a new Work"
    field :create_work, :work do
      arg(:metadata, non_null(:work_metadata_input))
      arg(:accession_number, non_null(:string))
      arg(:work_type, non_null(:work_type))
      arg(:visibility, non_null(:visibility))
      arg(:file_sets, list_of(:file_set_input))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.create_work/3)
    end

    @desc "Delete a Work"
    field :delete_work, :work do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.delete_work/3)
    end
  end

  @desc "A work object"
  object :work do
    field :id, non_null(:id)
    field :accession_number, non_null(:string)
    field :metadata, :work_metadata
    field :work_type, non_null(:work_type)
    field :visibility, non_null(:visibility)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)

    field :file_sets, list_of(:file_set), resolve: dataloader(Data)
  end

  #
  # Input Object Types
  #

  @desc "Filters for the list of works"
  input_object :work_filter do
    @desc "Matching a title"
    field :matching, :string

    @desc "By visibility"
    field :visibility, :visibility

    @desc "By work_type"
    field :work_type, :work_type
  end

  @desc "Same as `work_metadata`. This represents all metadata associated with a work object. It is stored in a single json field."
  input_object :work_metadata_input do
    field :title, :string
  end

  #
  # Object Types
  #

  @desc "`work_metadata` represents all metadata associated with a work object. It is stored in a single json field."
  object :work_metadata do
    field :title, :string
    field :description, :string
  end

  @desc "visibility setting for the object"
  enum :visibility do
    value(:open, as: "open", description: "Public")
    value(:authenticated, as: "authenticated", description: "Institution")
    value(:restricted, as: "restricted", description: "Private")
  end

  @desc "work types"
  enum :work_type do
    value(:image, as: "image", description: "Image")
    value(:video, as: "video", description: "Video")
    value(:document, as: "document", description: "Document")
  end
end
