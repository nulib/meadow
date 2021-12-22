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

    @desc "Get verification status for a work's fileSets"
    field :verify_file_sets, list_of(:file_set_verification_status) do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.verify_file_sets/3)
    end

    @desc "Get last modified timestamp and etag for IIIF manifest"
    field :iiif_manifest_headers, :iiif_manifest_headers do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.iiif_manifest_headers/3)
    end
  end

  object :work_mutations do
    @desc "Create a new Work"
    field :create_work, :work do
      arg(:administrative_metadata, non_null(:work_administrative_metadata_input))
      arg(:descriptive_metadata, non_null(:work_descriptive_metadata_input))
      arg(:accession_number, non_null(:string))
      arg(:work_type, :coded_term_input)
      arg(:visibility, :coded_term_input)
      arg(:published, :boolean)
      arg(:reading_room, :boolean)
      arg(:file_sets, list_of(:file_set_input))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.create_work/3)
    end

    @desc "Update a Work"
    field :update_work, :work do
      arg(:id, non_null(:id))
      arg(:work, non_null(:work_update_input))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.update_work/3)
    end

    @desc "Set the representative FileSet (Access or Auxiliary) for a Work"
    field :set_work_image, :work do
      arg(:work_id, non_null(:id))
      arg(:file_set_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.set_work_image/3)
    end

    @desc "Delete a Work"
    field :delete_work, :work do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.delete_work/3)
    end

    @desc "Add a work to a Collection"
    field :add_work_to_collection, :work do
      arg(:work_id, non_null(:id))
      arg(:collection_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.add_work_to_collection/3)
    end

    @desc "Change the order of a work's access files"
    field :update_access_file_order, :work do
      arg(:work_id, non_null(:id))
      arg(:file_set_ids, list_of(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.update_access_file_order/3)
    end
  end

  @desc "A work object"
  object :work do
    field :id, non_null(:id)
    field :accession_number, non_null(:string)
    field :administrative_metadata, :work_administrative_metadata
    field :descriptive_metadata, :work_descriptive_metadata
    field :work_type, :coded_term
    field :visibility, :coded_term
    field :published, :boolean
    field :reading_room, :boolean

    field :manifest_url, :string do
      resolve(fn work, _, _ ->
        {:ok, Works.iiif_manifest_url(work.id, work.work_type.id)}
      end)
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
    field :collection, :collection, resolve: dataloader(Data)
    field :file_sets, list_of(:file_set), resolve: dataloader(OrderedFileSets)
    field :representative_image, :string

    field :project, :project, resolve: dataloader(Data)
    field :ingest_sheet, :ingest_sheet, resolve: dataloader(Data)
  end

  @desc "`controlled_fields` represents all controlled descriptive metadata fields on a work."
  object :controlled_fields do
    field :contributor, list_of(:controlled_metadata_entry)
    field :creator, list_of(:controlled_metadata_entry)
    field :genre, list_of(:controlled_metadata_entry)
    field :language, list_of(:controlled_metadata_entry)
    field :location, list_of(:controlled_metadata_entry)
    field :notes, list_of(:note_entry)
    field :related_url, list_of(:related_url_entry)
    field :style_period, list_of(:controlled_metadata_entry)
    field :subject, list_of(:controlled_metadata_entry)
    field :technique, list_of(:controlled_metadata_entry)
  end

  @desc "`uncontrolled_descriptive_fields` represents all uncontrolled descriptive metadata fields."
  object :uncontrolled_descriptive_fields do
    field :abstract, list_of(:string)
    field :alternate_title, list_of(:string)
    field :box_name, list_of(:string)
    field :box_number, list_of(:string)
    field :caption, list_of(:string)
    field :catalog_key, list_of(:string)
    field :cultural_context, list_of(:string)
    field :description, list_of(:string)
    field :folder_name, list_of(:string)
    field :folder_number, list_of(:string)
    field :identifier, list_of(:string)
    field :keywords, list_of(:string)
    field :legacy_identifier, list_of(:string)
    field :terms_of_use, :string
    field :physical_description_material, list_of(:string)
    field :physical_description_size, list_of(:string)
    field :provenance, list_of(:string)
    field :publisher, list_of(:string)
    field :related_material, list_of(:string)
    field :rights_holder, list_of(:string)
    field :scope_and_contents, list_of(:string)
    field :series, list_of(:string)
    field :source, list_of(:string)
    field :table_of_contents, list_of(:string)
    field :title, :string
  end

  @desc "`work_descriptive_metadata` represents all descriptive metadata associated with a work object."
  object :work_descriptive_metadata do
    field :ark, :string
    field :citation, list_of(:string)
    field :date_created, list_of(:edtf_date_entry)
    field :license, :coded_term
    field :notes, list_of(:note_entry)
    field :rights_statement, :coded_term
    field :related_url, list_of(:related_url_entry)
    import_fields(:uncontrolled_descriptive_fields)
    import_fields(:controlled_fields)
  end

  object :uncontrolled_administrative_fields do
    field :project_name, list_of(:string)
    field :project_desc, list_of(:string)
    field :project_proposer, list_of(:string)
    field :project_manager, list_of(:string)
    field :project_task_number, list_of(:string)
    field :project_cycle, :string
  end

  @desc "`work_administrative_metadata` represents all administrative metadata associated with a work object. It is stored in a single json field."
  object :work_administrative_metadata do
    field :library_unit, :coded_term
    field :preservation_level, :coded_term
    field :status, :coded_term

    import_fields(:uncontrolled_administrative_fields)
  end

  @desc "Project info"
  object :work_project do
    field :id, :string
    field :title, :string
  end

  @desc "Sheet info"
  object :work_sheet do
    field :id, :id
    field :title, :string
  end

  @desc "Whether or not a file set's presence in preservation location is verified"
  object :file_set_verification_status do
    field :file_set_id, :id
    field :verified, :boolean
  end

  @desc "IIIF Manifest etag and last modified headers"
  object :iiif_manifest_headers do
    field :work_id, :id
    field :manifest_url, :string
    field :etag, :string
    field :last_modified, :string
  end

  #
  # Input Object Types
  #

  @desc "Fields that can be updated on a work object"
  input_object :work_update_input do
    field :administrative_metadata, :work_administrative_metadata_input
    field :descriptive_metadata, :work_descriptive_metadata_input
    field :visibility, :coded_term_input
    field :published, :boolean
    field :reading_room, :boolean
    field :collection_id, :id
  end

  @desc "Input fields for works administrative metadata"
  input_object :work_administrative_metadata_input do
    field :library_unit, :coded_term_input
    field :preservation_level, :coded_term_input
    field :status, :coded_term_input

    import_fields(:uncontrolled_administrative_fields)
  end

  @desc "Input fields for works descriptive metadata"
  input_object :work_descriptive_metadata_input do
    field :date_created, list_of(:edtf_date_input)
    field :license, :coded_term_input
    field :notes, list_of(:note_entry_input)
    field :rights_statement, :coded_term_input
    field :related_url, list_of(:related_url_entry_input)
    import_fields(:controlled_fields_input)
    import_fields(:uncontrolled_descriptive_fields)
  end

  @desc "`controlled_fields_input` controlled fields that can be updated on a work object"
  input_object :controlled_fields_input do
    field :contributor, list_of(:controlled_metadata_entry_input)
    field :creator, list_of(:controlled_metadata_entry_input)
    field :genre, list_of(:controlled_metadata_entry_input)
    field :language, list_of(:controlled_metadata_entry_input)
    field :location, list_of(:controlled_metadata_entry_input)
    field :subject, list_of(:controlled_metadata_entry_input)
    field :style_period, list_of(:controlled_metadata_entry_input)
    field :technique, list_of(:controlled_metadata_entry_input)
  end

  @desc "Filters for the list of works"
  input_object :work_filter do
    @desc "Matching a title"
    field :matching, :string
  end
end
