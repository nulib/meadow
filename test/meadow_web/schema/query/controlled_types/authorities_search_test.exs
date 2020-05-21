defmodule MeadowWeb.Schema.Query.AuthoritiesSearchTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Authoritex.Mock

  load_gql(MeadowWeb.Schema, "test/gql/AuthoritiesSearch.gql")

  @data [
    %{
      id: "mock:result1",
      label: "First Result",
      qualified_label: "First Result (1)",
      hint: "(1)"
    },
    %{
      id: "mock:result2",
      label: "Second Result",
      qualified_label: "Second Result (2)",
      hint: "(2)"
    }
  ]

  describe "AuthoritiesSearch.gql" do
    setup do
      Mock.set_data(@data)
      :ok
    end

    test "Is a valid query" do
      result =
        query_gql(variables: %{"authority" => "mock", "query" => "test"}, context: gql_context())

      assert {:ok, %{data: query_data}} = result

      with result <- get_in(query_data, ["authoritiesSearch"]) do
        assert result
               |> Enum.member?(%{
                 "id" => "mock:result2",
                 "label" => "Second Result",
                 "hint" => "(2)"
               })
      end
    end
  end
end
