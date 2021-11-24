defmodule MeadowWeb.Schema.Data.ControlledTermTypes do
  @moduledoc """
  Absinthe Schema for ControlledTermTypes

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data.AuthoritiesSearch
  alias MeadowWeb.Resolvers.Data.ControlledVocabulary
  alias MeadowWeb.Schema.Middleware

  object :controlled_term_queries do
    @desc "Get values from a code list table (for use in dropdowns, etc)"
    field :code_list, list_of(:coded_term) do
      arg(:scheme, non_null(:code_list_scheme))
      middleware(Middleware.Authenticate)
      resolve(&ControlledVocabulary.code_list/3)
    end

    @desc "Get the label for a controlled_term by its id"
    field :fetch_controlled_term_label, :controlled_value do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)

      resolve(&AuthoritiesSearch.fetch_label/2)
    end

    @desc "Get the label for a coded_term by its id and scheme"
    field :fetch_coded_term_label, :coded_term do
      arg(:id, non_null(:id))
      arg(:scheme, non_null(:code_list_scheme))
      middleware(Middleware.Authenticate)
      resolve(&ControlledVocabulary.fetch_coded_term_label/3)
    end

    @desc "Get a list of authority search results by its authority"
    field :authorities_search, list_of(:controlled_value) do
      arg(:authority, non_null(:id))
      arg(:query, non_null(:string))
      middleware(Middleware.Authenticate)

      resolve(&AuthoritiesSearch.search/2)
    end
  end

  @desc "Search or fetch result"
  object :controlled_value do
    field :id, :id
    field :label, :string
    field :hint, :string
  end

  @desc "Controlled value associated with a role"
  object :controlled_term do
    field :id, :id
    field :label, :string
  end

  @desc "Controlled metadata entry"
  object :controlled_metadata_entry do
    field :term, :controlled_term
    field :role, :coded_term
  end

  @desc "An entry from a code list"
  object :coded_term do
    field :id, :id
    field :label, :string
    field :scheme, :code_list_scheme
  end

  @desc "EDTF Date"
  object :edtf_date_entry do
    field :edtf, :string
    field :humanized, :string
  end

  @desc "NoteEntry"
  object :note_entry do
    field :note, :string
    field :type, :coded_term
  end

  @desc "RelatedURLEntry"
  object :related_url_entry do
    field :url, :string
    field :label, :coded_term
  end

  @desc "Controlled Vocab input, id required, label is looked up on the backend. Provide role for compound vocabs"
  input_object :controlled_metadata_entry_input do
    field :term, non_null(:id)
    field :role, :coded_term_input
  end

  @desc "Input for code lookup in code list table. Provide id and scheme"
  input_object :coded_term_input do
    field :id, :id
    field :scheme, :code_list_scheme
  end

  @desc "EDTF date input"
  input_object :edtf_date_input do
    field :edtf, :string
  end

  @desc "Note input"
  input_object :note_entry_input do
    field :note, :string
    field :type, :coded_term_input
  end

  @desc "Related URL input"
  input_object :related_url_entry_input do
    field :url, :string
    field :label, :coded_term_input
  end

  @desc "Schemes for code list table. (Ex: Subjects, MARC relators, prevervation levels, etc)"
  enum :code_list_scheme do
    value(:authority, as: "authority", description: "Authority")
    value(:file_set_role, as: "file_set_role", description: "File Set Role")
    value(:library_unit, as: "library_unit", description: "Library Unit")
    value(:license, as: "license", description: "License")
    value(:marc_relator, as: "marc_relator", description: "MARC Relator")
    value(:note_type, as: "note_type", description: "Note Type")
    value(:preservation_level, as: "preservation_level", description: "Preservation Level")
    value(:rights_statement, as: "rights_statement", description: "Rights Statement")
    value(:related_url, as: "related_url", description: "Related URL")
    value(:subject_role, as: "subject_role", description: "Subject Role")
    value(:status, as: "status", description: "Status")
    value(:visibility, as: "visibility", description: "Visibility")
    value(:work_type, as: "work_type", description: "Work Type")
  end
end
