defmodule MeadowWeb.Resolvers.Data.AuthoritiesSearch do
  @moduledoc "GraphQL Resolvers for authority searching"

  def search(%{authority: code, query: query}, _) do
    Authoritex.search(code, query)
  end

  def fetch_label(%{id: id}, _) do
    Authoritex.fetch(id)
  end
end
