defmodule MeadowWeb.Schema.Mutation.CreateCollectionTest do
  use MeadowWeb.ConnCase, async: true
  use MeadowWeb.GQLCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "assets/js/gql/CreateCollection.gql")

  test "should be a valid mutation", %{gql_context: gctx} do
    result =
      query_gql(
        variables: %{"name" => "The collection name"},
        context: gctx
      )

    assert {:ok, query_data} = result

    collection_name = get_in(query_data, [:data, "createCollection", "name"])
    assert collection_name == "The collection name"
  end
end
