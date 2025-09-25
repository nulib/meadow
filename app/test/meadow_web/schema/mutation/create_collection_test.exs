defmodule MeadowWeb.Schema.Mutation.CreateCollectionTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateCollection.gql")

  test "should be a valid mutation" do
    result =
      query_gql(
        variables: %{"title" => "The collection title"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collection_title = get_in(query_data, [:data, "createCollection", "title"])
    assert collection_title == "The collection title"
  end

  describe "authorization" do
    test "viewers are not authorized to create collections" do
      {:ok, result} =
        query_gql(
          variables: %{"title" => "The collection title"},
          context: gql_context(%{role: :user})
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "managers and above are authorized to create collections" do
      {:ok, result} =
        query_gql(
          variables: %{"title" => "The collection title"},
          context: gql_context(%{role: :manager})
        )

      assert result.data["createCollection"]
    end
  end
end
