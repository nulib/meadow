defmodule MeadowWeb.Schema.Mutation.DeleteCollectionTest do
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

    assert {:ok, query_data} = result
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
