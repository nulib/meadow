defmodule MeadowWeb.Schema.Query.FetchControlledTermLabelTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Authoritex.Mock

  load_gql(MeadowWeb.Schema, "test/gql/FetchControlledTermLabel.gql")

  @data [
    %{
      id: "mock:result1",
      label: "First Result",
      qualified_label: "First Result (1)",
      hint: "(1)"
    }
  ]

  describe "FetchControlledTermLabel.gql" do
    setup do
      Mock.set_data(@data)
      :ok
    end

    test "Is a valid query" do
      result = query_gql(variables: %{"id" => "mock:result1"}, context: gql_context())

      assert {:ok, %{data: query_data}} = result

      with result <- get_in(query_data, ["fetchControlledTermLabel"]) do
        assert(result == %{"label" => "First Result"})
      end
    end

    test "Query an invalid ID" do
      result = query_gql(variables: %{"id" => "mock:result0"}, context: gql_context())

      assert {:ok, %{errors: [error]}} = result
      assert error.message == "404"
    end
  end
end
