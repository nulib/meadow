defmodule MeadowWeb.Schema.Query.FetchControlledTermLabelTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/FetchControlledTermLabel.gql")

  describe "FetchControlledTermLabel.gql" do
    test "Is a valid query" do
      result = query_gql(variables: %{"id" => "mock1:result1"}, context: gql_context())

      assert {:ok, %{data: query_data}} = result

      with result <- get_in(query_data, ["fetchControlledTermLabel"]) do
        assert(result == %{"label" => "First Result"})
      end
    end

    test "Query an invalid ID" do
      result = query_gql(variables: %{"id" => "mock0:result0"}, context: gql_context())

      assert {:ok, %{errors: [error]}} = result
      assert error.message == "unknown_authority"
    end
  end
end
