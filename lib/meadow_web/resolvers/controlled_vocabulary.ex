defmodule MeadowWeb.Resolvers.Data.ControlledVocabulary do
  @moduledoc "GraphQL Resolvers for Controlled and Coded terms"

  alias Meadow.Data.CodedTerms

  def code_list(_, %{scheme: scheme}, _) do
    {:ok, CodedTerms.list_coded_terms(scheme)}
  end

  def fetch_controlled_term_label(_, %{id: id, scheme: scheme}, _) do
    {:ok, CodedTerms.get_coded_term(id, scheme)}
  end
end
