defmodule MeadowWeb.Schema.Query.GetCollectionByIdTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetCollectionById.gql")

  test "should be a valid query" do
    collection_fixture = collection_fixture()

    result =
      query_gql(
        variables: %{"collectionId" => collection_fixture.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collection_title = get_in(query_data, [:data, "collection", "title"])
    assert collection_title == collection_fixture.title
    stats = get_in(query_data, [:data, "collection", "stats"])
    assert Map.keys(stats) == ~w(audio image published total unpublished video)
  end

  test "Should return nil for a non-existent collection" do
    result = query_gql(variables: %{"collectionId" => 100})
    assert {:ok, %{data: %{"collection" => nil}}} = result
  end
end
