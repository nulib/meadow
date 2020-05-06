defmodule MeadowWeb.Schema.Data.ControlledTermTypes do
  @moduledoc """
  Absinthe Schema for ControlledTermTypes

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Schema.Middleware

  object :controlled_term_queries do
    @desc "NOT YET IMPLEMENTED. Get values from a code list table (for use in dropdowns, etc)"
    field :code_list, list_of(:coded_term) do
      arg(:scheme, non_null(:code_list_scheme))
      middleware(Middleware.Authenticate)

      resolve(fn %{scheme: _scheme}, _ ->
        {:ok, []}
      end)
    end

    @desc "NOT YET IMPLEMENTED Get the label for a controlled_term by its id"
    field :fetch_controlled_term_label, :controlled_term do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)

      resolve(fn %{id: _id}, _ ->
        {:ok, nil}
      end)
    end

    @desc "NOT YET IMPLEMENTED Get the label for a coded_term by its id and scheme"
    field :fetch_coded_term_label, :coded_term do
      arg(:id, non_null(:id))
      arg(:scheme, non_null(:code_list_scheme))
      middleware(Middleware.Authenticate)

      resolve(fn %{id: _id}, _ ->
        {:ok, nil}
      end)
    end

    @desc "NOT YET IMPLEMENTED Get the label for a code list item by its id"
    field :authorities_search, list_of(:controlled_value) do
      arg(:authority, non_null(:coded_term_input))
      arg(:query, non_null(:string))
      middleware(Middleware.Authenticate)

      resolve(fn %{authority: _authority, query: _query}, _ ->
        {:ok, nil}
      end)
    end
  end

  @desc "NOT YET IMPLEMENTED"
  object :controlled_value do
    field :id, :id
    field :label, :string
  end

  @desc "NOT YET IMPLEMENTED"
  object :controlled_term do
    import_fields(:controlled_value)
    field :role, :coded_term
  end

  @desc "NOT YET IMPLEMENTED"
  object :coded_term do
    field :id, :id
    field :label, :string
    field :scheme, :code_list_scheme
  end

  @desc "NOT YET IMPLEMENTED Controlled Vocab input, id required, label is looked up on the backend. Provide role for compound vocabs"
  input_object :controlled_term_input do
    field :id, non_null(:id)
    field :role, :coded_term_input
  end

  @desc "NOT YET IMPLEMENTED Input for code lookup in code list table. Provide id and scheme"
  input_object :coded_term_input do
    field :id, non_null(:id)
    field :scheme, :code_list_scheme
  end

  @desc "NOT YET IMPLEMENTED: Schemes for code list table. (Ex: Subjects, MARC relators, prevervation levels, etc)"
  enum :code_list_scheme do
    value(:authorities, as: "authorities", description: "Authorities")
    value(:license, as: "license", description: "License")
    value(:marc_relator, as: "marc_relator", description: "MARC Relator")
    value(:preservation_level, as: "preservation_level", description: "Preservation Level")
    value(:rights_statement, as: "rights_statement", description: "Rights Statement")
    value(:subject, as: "subjects", description: "Subject")
    value(:status, as: "status", description: "Status")
    value(:visibility, as: "visibility", description: "Visibility")
    value(:work_type, as: "work_type", description: "Work Type")
  end
end
