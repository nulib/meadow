defmodule MeadowWeb.Resolvers.Data.AuthoritiesSearch do
  @moduledoc "GraphQL Resolvers for authority searching"

  alias Meadow.Data.ControlledTerms

  def search(
        %{authority: "nul-authority", query: <<"info:nul/", _::binary-size(36)>> = query},
        _
      ) do
    case Authoritex.fetch(query) do
      {:ok, %{id: id, label: label, hint: hint}} -> {:ok, [%{id: id, label: label, hint: hint}]}
      _ -> Authoritex.search("nul-authority", query)
    end
  end

  def search(%{authority: code, query: query}, _) do
    Authoritex.search(code, query)
  end

  def fetch_label(%{id: id}, _) do
    case ControlledTerms.fetch(id) do
      {{:ok, _}, term} -> {:ok, term}
      other -> other
    end
  end
end
