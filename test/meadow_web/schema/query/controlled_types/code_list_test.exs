defmodule MeadowWeb.Schema.Query.CodeListTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CodeList.gql")

  describe "codeList.gql" do
    test "Is a valid query" do
      result = query_gql(variables: %{scheme: "RIGHTS_STATEMENT"}, context: gql_context())
      assert {:ok, query_data} = result
    end
  end
end
