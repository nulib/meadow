defmodule MeadowWeb.Schema.Data.WorkTypes do
  @moduledoc """
  Absinthe Schema for WorkTypes

  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Meadow.Data
  alias Meadow.Data.Works
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
      arg(:administrative_metadata, non_null(:work_administrative_metadata_input))
      arg(:descriptive_metadata, non_null(:work_descriptive_metadata_input))
      arg(:accession_number, non_null(:string))
      arg(:work_type, non_null(:work_type))
      arg(:visibility, non_null(:visibility))
      arg(:published, :boolean)
      arg(:file_sets, list_of(:file_set_input))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.create_work/3)
    end

    @desc "Update a Work"
    field :update_work, :work do
      arg(:id, non_null(:id))
      arg(:work, non_null(:work_update_input))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.update_work/3)
    end

    @desc "Set the representative FileSet for a Work"
    field :set_work_image, :work do
      arg(:work_id, non_null(:id))
      arg(:file_set_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.set_work_image/3)
    end

    @desc "Delete a Work"
    field :delete_work, :work do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.delete_work/3)
    end

    @desc "Add a work to a Collection"
    field :add_work_to_collection, :work do
      arg(:work_id, non_null(:id))
      arg(:collection_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.add_work_to_collection/3)
    end
  end

  @desc "A work object"
  object :work do
    field :id, non_null(:id)
    field :accession_number, non_null(:string)
    field :administrative_metadata, :work_administrative_metadata
    field :descriptive_metadata, :work_descriptive_metadata
    field :work_type, non_null(:work_type)
    field :visibility, non_null(:visibility)
    field :published, :boolean

    field :manifest_url, :string do
      resolve(fn work, _, _ ->
        {:ok, Works.iiif_manifest_url(work.id)}
      end)
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
    field :collection, :collection, resolve: dataloader(Data)
    field :file_sets, list_of(:file_set), resolve: dataloader(Data)
    field :representative_image, :string

    field :project, :work_project do
      resolve(fn work, _, _ ->
        {:ok, work.extra_index_fields.project}
      end)
    end

    field :sheet, :work_sheet do
      resolve(fn work, _, _ ->
        {:ok, work.extra_index_fields.sheet}
      end)
    end
  end

  @desc "`uncontrolled_descriptive_fields` represents all uncontrolled descriptive metadata fields."
  object :uncontrolled_descriptive_fields do
    field :abstract, list_of(:string)
    field :alternate_title, list_of(:string)
    field :box_name, list_of(:string)
    field :box_number, list_of(:string)
    field :call_number, list_of(:string)
    field :caption, list_of(:string)
    field :catalog_key, list_of(:string)
    field :description, list_of(:string)
    field :folder_name, list_of(:string)
    field :folder_number, list_of(:string)
    field :identifier, list_of(:string)
    field :keywords, list_of(:string)
    field :legacy_identifier, list_of(:string)
    field :notes, list_of(:string)
    field :physical_description_material, list_of(:string)
    field :physical_description_size, list_of(:string)
    field :provenance, list_of(:string)
    field :publisher, list_of(:string)
    field :related_url, list_of(:string)
    field :related_material, list_of(:string)
    field :rights_holder, list_of(:string)
    field :scope_and_contents, list_of(:string)
    field :series, list_of(:string)
    field :source, list_of(:string)
    field :table_of_contents, list_of(:string)
    field :title, :string
  end

  @desc "`work_descriptive_metadata` represents all descriptive metadata associated with a work object. It is stored in a single json field."
  object :work_descriptive_metadata do
    @desc "NOT YET IMPLEMENTED"
    field :contributor, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :creator, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :genre, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :language, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :location, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :style_period, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :subject, list_of(:controlled_vocabulary)
    @desc "NOT YET IMPLEMENTED"
    field :technique, list_of(:controlled_vocabulary)

    field :ark, :string
    field :citation, list_of(:string)
    import_fields(:uncontrolled_descriptive_fields)
  end

  @desc "`work_administrative_metadata` represents all administrative metadata associated with a work object. It is stored in a single json field."
  object :work_administrative_metadata do
    field :preservation_level, :integer
    field :rights_statement, :string
  end

  @desc "Project info"
  object :work_project do
    field :id, :string
    field :name, :string
  end

  @desc "Sheet info"
  object :work_sheet do
    field :id, :id
    field :name, :string
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

    @desc "By work type"
    field :work_type, :work_type
  end

  @desc "Same as `work_administrative_metadata`. This represents all administrative metadata associated with a work object. It is stored in a single json field."
  input_object :work_administrative_metadata_input do
    field :preservation_level, :integer
    field :rights_statement, :string
  end

  @desc "Same as `work_descriptive_metadata`. This represents all descriptive metadata associated with a work object. It is stored in a single json field."
  input_object :work_descriptive_metadata_input do
    @desc "NOT YET IMPLEMENTED"
    field :contributor, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :creator, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :genre, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :language, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :location, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :subject, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :style_period, list_of(:controlled_vocabulary_input)
    @desc "NOT YET IMPLEMENTED"
    field :technique, list_of(:controlled_vocabulary_input)

    import_fields(:uncontrolled_descriptive_fields)
  end

  @desc "Fields that can be updated on a work object"
  input_object :work_update_input do
    field :administrative_metadata, :work_administrative_metadata_input
    field :descriptive_metadata, :work_descriptive_metadata_input
    field :visibility, :visibility
    field :published, :boolean
    field :collection_id, :id
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
    value(:audio, as: "audio", description: "Audio")
    value(:video, as: "video", description: "Video")
    value(:document, as: "document", description: "Document")
  end
end
