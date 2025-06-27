defmodule MeadowWeb.Schema.Mutation.RemoveWorksFromCollectionTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Data.Collections
  alias Meadow.Repo

  load_gql(MeadowWeb.Schema, "test/gql/RemoveWorksFromCollection.gql")

  test "should be a valid mutation" do
    collection = collection_fixture()

    works = [
      work_fixture(%{collection_id: collection.id}),
      work_fixture(%{collection_id: collection.id}),
      work_fixture(%{collection_id: collection.id})
    ]

    collection = Collections.get_collection!(collection.id) |> Repo.preload(:works)
    assert collection.works |> length() == 3

    work_ids = works |> Enum.map(& &1.id)

    result =
      query_gql(
        variables: %{"workIds" => work_ids, "collectionId" => collection.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    assert get_in(query_data, [:data, "removeWorksFromCollection", "works"]) == []

    collection = Collections.get_collection!(collection.id) |> Repo.preload(:works)
    assert collection.works |> Enum.empty?()
  end

  describe "authorization" do
    test "viewers are not authorized to remove works from collections" do
      collection_fixture = collection_fixture()

      works = [
        work_fixture(%{collection_id: collection_fixture.id})
      ]

      {:ok, result} =
        query_gql(
          variables: %{
            "workIds" => Enum.map(works, & &1.id),
            "collectionId" => collection_fixture.id
          },
          context: %{current_user: %{role: :user}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end
  end
end
