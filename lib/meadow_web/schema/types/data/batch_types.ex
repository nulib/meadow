defmodule MeadowWeb.Schema.Data.BatchTypes do
  @moduledoc """
  Absinthe Schema for Batch Update Functionality

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data.Batches
  alias MeadowWeb.Schema.Middleware

  object :batch_mutations do
    @desc "Start a batch update operation"
    field :batch_update, :message do
      arg(:query, non_null(:string))
      @desc "`delete` deletes specific existing controlled values"
      arg(:delete, :batch_delete_input, default_value: %{})
      @desc "`add` appends to existing values (multi-valued fields only)"
      arg(:add, :batch_add_input, default_value: nil)
      @desc "`replace` replaces existing values (single and multi valued fields)"
      arg(:replace, :batch_replace_input, default_value: nil)
      middleware(Middleware.Authenticate)
      resolve(&Batches.update/3)
    end
  end

  object :message do
    field :message, :string
  end

  @desc "Input fields for batch add operations"
  input_object :batch_add_input do
    field :descriptive_metadata, :batch_add_descriptive_metadata_input
    field :administrative_metadata, :batch_add_administrative_metadata_input
  end

  @desc "Input fields for batch replace operations"
  input_object :batch_replace_input do
    field :collection_id, :id
    field :visibility, :coded_term_input
    field :published, :boolean
    field :descriptive_metadata, :batch_replace_descriptive_metadata_input
    field :administrative_metadata, :batch_replace_administrative_metadata_input
  end

  @desc "Input fields for batch delete operations"
  input_object :batch_delete_input do
    import_fields(:controlled_fields_input)
  end

  @desc "Input fields available for batch add (append) operations on works descriptive metadata"
  input_object :batch_add_descriptive_metadata_input do
    import_fields(:batch_editable_multi_valued_descriptive_metadata_input)
    import_fields(:controlled_fields_input)
  end

  @desc "Input fields available for batch add (append) operations on works administrative metadata"
  input_object :batch_add_administrative_metadata_input do
    import_fields(:batch_editable_multi_valued_administrative_metadata_input)
  end

  @desc "Input fields available for batch replace operations on works descriptive metadata"
  input_object :batch_replace_descriptive_metadata_input do
    field :title, :string
    field :terms_of_use, :string
    field :rights_statement, :coded_term_input
    field :license, :coded_term_input
    import_fields(:batch_editable_multi_valued_descriptive_metadata_input)
  end

  @desc "Input fields available for batch replace operations on works administrative metadata"
  input_object :batch_replace_administrative_metadata_input do
    field :library_unit, :coded_term_input
    field :preservation_level, :coded_term_input
    field :status, :coded_term_input
    field :project_cycle, :string
    import_fields(:batch_editable_multi_valued_administrative_metadata_input)
  end

  input_object :batch_editable_multi_valued_descriptive_metadata_input do
    field :abstract, list_of(:string)
    field :alternate_title, list_of(:string)
    field :box_name, list_of(:string)
    field :box_number, list_of(:string)
    field :caption, list_of(:string)
    field :catalog_key, list_of(:string)
    field :date_created, list_of(:edtf_date_input)
    field :description, list_of(:string)
    field :folder_name, list_of(:string)
    field :folder_number, list_of(:string)
    field :keywords, list_of(:string)
    field :notes, list_of(:string)
    field :physical_description_material, list_of(:string)
    field :physical_description_size, list_of(:string)
    field :provenance, list_of(:string)
    field :publisher, list_of(:string)
    field :related_material, list_of(:string)
    field :related_url, list_of(:related_url_entry_input)
    field :rights_holder, list_of(:string)
    field :scope_and_contents, list_of(:string)
    field :series, list_of(:string)
    field :source, list_of(:string)
    field :table_of_contents, list_of(:string)
  end

  input_object :batch_editable_multi_valued_administrative_metadata_input do
    field :project_name, list_of(:string)
    field :project_desc, list_of(:string)
    field :project_proposer, list_of(:string)
    field :project_manager, list_of(:string)
    field :project_manager, list_of(:string)
    field :project_task_number, list_of(:string)
  end
end
