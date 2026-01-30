defmodule MeadowWeb.Resolvers.Data.ControlledVocabulary do
  @moduledoc "GraphQL Resolvers for Controlled and Coded terms"

  alias Meadow.Data.{CodedTerms, ControlledTerms}

  def code_list(_, %{scheme: scheme}, _) do
    {:ok, CodedTerms.list_coded_terms(scheme)}
  end

  def fetch_coded_term_label(_, %{id: id, scheme: scheme}, _) do
    case CodedTerms.get_coded_term(id, scheme) do
      nil ->
        {:error, message: "is an invalid coded term for scheme #{String.upcase(scheme)}"}

      {{:ok, _}, term} ->
        {:ok, term}
    end
  end

  def obsolete_controlled_terms(_, %{limit: limit}, _) do
    {:ok, ControlledTerms.list_obsolete_terms(limit)}
  end
end
