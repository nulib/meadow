defmodule MeadowWeb.Schema.Mutation.CreateCollectionTest do
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
end
