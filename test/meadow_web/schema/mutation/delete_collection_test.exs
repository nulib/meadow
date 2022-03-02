defmodule MeadowWeb.Schema.Mutation.DeleteCollectionTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/DeleteCollection.gql")

  test "should be a valid mutation" do
    collection_fixture = collection_fixture()

    result =
      query_gql(
        variables: %{"collectionId" => collection_fixture.id},
        context: gql_context()
      )

    assert {:ok, _query_data} = result
  end

  test "should not allow non-empty collections to be deleted" do
    collection = collection_fixture()
    work_fixture(%{collection_id: collection.id})

    {:ok, result} =
      query_gql(
        variables: %{"collectionId" => collection.id},
        context: gql_context()
      )

    assert %{
             errors: [
               %{
                 message: "Could not delete collection",
                 details: %{"works" => "Works are still associated with this collection."}
               }
             ]
           } = result
  end

  describe "authorization" do
    test "viewers and editors are not authorized to delete collections" do
      collection_fixture = collection_fixture()

      {:ok, result} =
        query_gql(
          variables: %{"collectionId" => collection_fixture.id},
          context: %{current_user: %{role: "Editor"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "managers and above are authorized to delete collections" do
      collection_fixture = collection_fixture()

      {:ok, result} =
        query_gql(
          variables: %{"collectionId" => collection_fixture.id},
          context: %{current_user: %{role: "Manager"}}
        )

      assert result.data["deleteCollection"]
    end
  end
end
