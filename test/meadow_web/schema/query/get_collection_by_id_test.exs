defmodule MeadowWeb.Schema.Query.GetCollectionByIdTest do
  use MeadowWeb.ConnCase, async: true
  use MeadowWeb.GQLCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "assets/js/gql/GetCollectionById.gql")

  test "should be a valid query", %{gql_context: gctx} do
    collection_fixture = collection_fixture()

    result =
      query_gql(
        variables: %{"collectionId" => collection_fixture.id},
        context: gctx
      )

    assert {:ok, query_data} = result

    collection_name = get_in(query_data, [:data, "collection", "name"])
    assert collection_name == collection_fixture.name
  end

  test "Should return nil for a non-existant collection" do
    result = query_gql(variables: %{"collectionId" => 100})
    assert {:ok, %{data: %{"collection" => nil}}} = result
  end
end
