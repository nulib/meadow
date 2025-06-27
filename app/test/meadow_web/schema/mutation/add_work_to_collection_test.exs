defmodule MeadowWeb.Schema.Mutation.AddWorkToCollectionTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, acync: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/AddWorkToCollection.gql")

  test "should be a valid mutation" do
    collection = collection_fixture()
    work = work_fixture()

    result =
      query_gql(
        variables: %{"workId" => work.id, "collectionId" => collection.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collection_id = get_in(query_data, [:data, "addWorkToCollection", "collection", "id"])
    assert collection_id == collection.id
  end

  describe "authorization" do
    test "viewers are not authoried to add works to collections" do
      collection = collection_fixture()
      work = work_fixture()

      result =
        query_gql(
          variables: %{"workId" => work.id, "collectionId" => collection.id},
          context: %{current_user: %{role: :user}}
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end
  end
end
