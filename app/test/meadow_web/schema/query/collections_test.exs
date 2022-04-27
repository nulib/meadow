defmodule MeadowWeb.Schema.Query.CollectionsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetCollections.gql")

  test "should be a valid query" do
    collection_fixture()
    collection_fixture()
    collection_fixture()

    result =
      query_gql(
        variables: %{},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collections = get_in(query_data, [:data, "collections"])
    assert length(collections) == 3
  end
end
