defmodule MeadowWeb.Schema.Mutation.CreateCollectionTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateCollection.gql")

  test "should be a valid mutation" do
    result =
      query_gql(
        variables: %{"name" => "The collection name"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collection_name = get_in(query_data, [:data, "createCollection", "name"])
    assert collection_name == "The collection name"
  end
end
