defmodule MeadowWeb.Schema.Mutation.DeleteCollectionTest do
  use MeadowWeb.ConnCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/DeleteCollection.gql")

  test "should be a valid mutation" do
    collection_fixture = collection_fixture()

    result =
      query_gql(
        variables: %{"collection_id" => collection_fixture.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result
  end
end
