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
      arg(:delete, :batch_delete_input, default_value: %{})
      arg(:add, :batch_add_input, default_value: nil)
      arg(:replace, :batch_add_input, default_value: nil)
      middleware(Middleware.Authenticate)
      resolve(&Batches.update/3)
    end
  end

  object :message do
    field :message, :string
  end

  @desc "Input fields for batch add operations"
  input_object :batch_add_input do
    field :collection_id, :id
    field :descriptive_metadata, :work_descriptive_metadata_input
  end

  @desc "Input fields for batch delete operations"
  input_object :batch_delete_input do
    import_fields(:controlled_fields_input)
  end
end
