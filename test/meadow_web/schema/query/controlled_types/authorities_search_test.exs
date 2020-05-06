defmodule MeadowWeb.Schema.Query.AuthoritiesSearchTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/AuthoritiesSearch.gql")

  describe "AuthoritiesSearch.gql" do
    test "Is a valid query" do
      result =
        query_gql(
          variables: %{authority: "ULAN", query: "Fox"},
          context: gql_context()
        )

      assert {:ok, query_data} = result
    end
  end
end
