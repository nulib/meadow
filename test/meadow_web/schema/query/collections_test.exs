defmodule MeadowWeb.Schema.Query.CollectionsTest do
  use MeadowWeb.ConnCase, async: true
  use MeadowWeb.GQLCase

  load_gql(MeadowWeb.Schema, "assets/js/gql/GetCollections.gql")

  test "should be a valid query", %{gql_context: gctx} do
    collection_fixture()
    collection_fixture()
    collection_fixture()

    result =
      query_gql(
        variables: %{},
        context: gctx
      )

    assert {:ok, query_data} = result

    collections = get_in(query_data, [:data, "collections"])
    assert length(collections) == 3
  end
end
