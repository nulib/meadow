defmodule MeadowWeb.Schema.Mutation.DeleteCollectionTest do
  use MeadowWeb.ConnCase, async: true
  use MeadowWeb.GQLCase

  load_gql(MeadowWeb.Schema, "assets/js/gql/DeleteCollection.gql")

  test "should be a valid mutation", %{gql_context: gctx} do
    collection_fixture = collection_fixture()

    result =
      query_gql(
        variables: %{"collection_id" => collection_fixture.id},
        context: gctx
      )

    assert {:ok, query_data} = result
  end
end
