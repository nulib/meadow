defmodule MeadowWeb.Schema.Data.BatchTypes do
  @moduledoc """
  Absinthe Schema for Batch Update Functionality

  """
  use Absinthe.Schema.Notation
  import MeadowWeb.Schema.MetadataFields
  alias Meadow.Data.Schemas.{WorkAdministrativeMetadata, WorkDescriptiveMetadata}
  alias MeadowWeb.Resolvers.Data.Batches
  alias MeadowWeb.Schema.Middleware

  object :batch_queries do
    @desc "Get all batches"
    field :batches, list_of(:batch) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Batches.batches/3)
    end

    @desc "Get a batch by id"
    field :batch, :batch do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Batches.batch/3)
    end
  end

  object :batch_mutations do
    @desc "Start a batch update operation"
    field :batch_update, :batch do
      arg(:nickname, :string)
      arg(:query, non_null(:string))
      @desc "`delete` deletes specific existing controlled values"
      arg(:delete, :batch_delete_input, default_value: %{})
      @desc "`add` appends to existing values (multi-valued fields only)"
      arg(:add, :batch_add_input, default_value: nil)
      @desc "`replace` replaces existing values (single and multi valued fields)"
      arg(:replace, :batch_replace_input, default_value: nil)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Batches.update/3)
    end

    @desc "Start a batch delete operation"
    field :batch_delete, :batch do
      arg(:nickname, :string)
      arg(:query, non_null(:string))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Batches.delete/3)
    end
  end

  #
  # Object Types
  #

  @desc "Fields for a `batch` object "
  object :batch do
    field(:id, :id)
    field(:nickname, :string)
    field(:status, :batch_status)
    field(:user, :string)
    field(:started, :datetime)
    field(:type, :batch_type)
    field(:works_updated, :integer)
    field(:query, :string)
    field(:add, :string)
    field(:delete, :string)
    field(:replace, :string)
    field(:error, :string)
  end

  @desc "Input fields for batch add operations"
  input_object :batch_add_input do
    field(:descriptive_metadata, :batch_add_descriptive_metadata_input)
    field(:administrative_metadata, :batch_add_administrative_metadata_input)
  end

  @desc "Input fields for batch replace operations"
  input_object :batch_replace_input do
    field(:collection_id, :id)
    field(:visibility, :coded_term_input)
    field(:published, :boolean)
    field(:descriptive_metadata, :batch_replace_descriptive_metadata_input)
    field(:administrative_metadata, :batch_replace_administrative_metadata_input)
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
    metadata_fields(WorkDescriptiveMetadata, :coded, :coded_term_input)
    metadata_fields(WorkDescriptiveMetadata, :string, :string)
    import_fields(:batch_editable_multi_valued_descriptive_metadata_input)
  end

  @desc "Input fields available for batch replace operations on works administrative metadata"
  input_object :batch_replace_administrative_metadata_input do
    metadata_fields(WorkAdministrativeMetadata, :coded, :coded_term_input)
    metadata_fields(WorkAdministrativeMetadata, :string, :string)
    import_fields(:batch_editable_multi_valued_administrative_metadata_input)
  end

  input_object :batch_editable_multi_valued_descriptive_metadata_input do
    metadata_fields(WorkDescriptiveMetadata, :values, list_of(:string), except: [:citation])
    field(:date_created, list_of(:edtf_date_input))
    field(:notes, list_of(:note_entry_input))
    field(:related_url, list_of(:related_url_entry_input))
  end

  input_object :batch_editable_multi_valued_administrative_metadata_input do
    metadata_fields(WorkAdministrativeMetadata, :values, list_of(:string))
  end

  @desc "Batch status values"
  enum :batch_status do
    value(:queued, as: "queued", description: "queued")
    value(:in_progress, as: "in_progress", description: "In Progress")
    value(:error, as: "error", description: "Error")
    value(:complete, as: "complete", description: "Completed Successfully")
  end

  @desc "Batch type values"
  enum :batch_type do
    value(:update, as: "update", description: "Batch Update")
    value(:delete, as: "delete", description: "Batch Delete")
  end
end
