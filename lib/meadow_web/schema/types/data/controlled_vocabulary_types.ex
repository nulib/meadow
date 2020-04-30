defmodule MeadowWeb.Schema.Data.ControlledVocabularyTypes do
  @moduledoc """
  Absinthe Schema for ControlledVocabularyTypes

  """
  use Absinthe.Schema.Notation

  @desc "NOT YET IMPLEMENTED"
  object :controlled_vocabulary do
    field :id, :id
    field :label, :string
    field :role, :code_list_item
  end

  @desc "NOT YET IMPLEMENTED"
  object :code_list_item do
    field :id, :id
    field :label, :string
    field :scheme, :code_list_scheme
  end

  @desc "NOT YET IMPLEMENTED Controlled Vocab input, id required, label is looked up on the backend. Provide role for compound vocabs"
  input_object :controlled_vocabulary_input do
    field :id, :id
    field :role, :code_list_item_input
  end

  @desc "NOT YET IMPLEMENTED Input for code lookup in code list table. Provide id and scheme"
  input_object :code_list_item_input do
    field :id, :id
    field :scheme, :code_list_scheme
  end

  @desc "NOT YET IMPLEMENTED: Schemes for code list table. (Ex: Subjects, MARC relators, prevervation levels, etc)"
  enum :code_list_scheme do
    value(:rights_statement, as: "rights_statement", description: "Rights Statement")
    value(:preservation_level, as: "preservation_level", description: "Preservation Level")
    value(:status, as: "status", description: "Status")
    value(:license, as: "license", description: "License")
    value(:marc_relator, as: "marc_relator", description: "MARC Relator")
    value(:subject, as: "subjects", description: "Subject")
  end
end
