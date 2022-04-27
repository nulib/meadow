defmodule MeadowWeb.Schema.Query.AuthoritiesSearchTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/AuthoritiesSearch.gql")

  describe "AuthoritiesSearch.gql" do
    test "Is a valid query" do
      result =
        query_gql(variables: %{"authority" => "mock", "query" => "test"}, context: gql_context())

      assert {:ok, %{data: query_data}} = result

      with result <- get_in(query_data, ["authoritiesSearch"]) do
        assert result
               |> Enum.member?(%{
                 "id" => "mock1:result2",
                 "label" => "Second Result",
                 "hint" => "(2)"
               })
      end
    end
  end
end
