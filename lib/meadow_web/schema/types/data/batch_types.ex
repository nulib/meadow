defmodule MeadowWeb.Schema.Data.BatchTypes do
  @moduledoc """
  Absinthe Schema for Batch Update Functionality

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Schema.Middleware

  object :batch_mutations do
    @desc "Start a batch update operation"
    field :batch_update, :message do
      arg(:query, non_null(:string))
      arg(:delete, non_null(:batch_update_input))
      middleware(Middleware.Authenticate)

      resolve(fn _, _ ->
        {:ok, %{message: "Batch started"}}
      end)
    end
  end

  object :message do
    field :message, :string
  end

  @desc "Input fields for batch update opereations"
  input_object :batch_update_input do
    import_fields(:controlled_fields_input)
  end
end
