defmodule MeadowWeb.Resolvers.Data.AuthoritiesSearch do
  @moduledoc "GraphQL Resolvers for authority searching"

  alias Meadow.Data.ControlledTerms

  def search(
        %{authority: "nul-authority", query: <<"info:nul/", _::binary-size(36)>> = query} = args,
        _
      ) do
    case Authoritex.fetch(query) do
      {:ok, %{id: id, label: label, hint: hint}} -> {:ok, [%{id: id, label: label, hint: hint}]}
      _ -> do_search(args)
    end
  end

  def search(args, _), do: do_search(args)

  defp do_search(%{authority: code, query: query, limit: limit}) do
    Authoritex.search(code, query, limit)
  end

  defp do_search(%{authority: code, query: query}) do
    Authoritex.search(code, query)
  end

  def fetch_label(%{id: id}, _) do
    case ControlledTerms.fetch(id) do
      {{:ok, _}, term} -> {:ok, term}
      other -> other
    end
  end
end
