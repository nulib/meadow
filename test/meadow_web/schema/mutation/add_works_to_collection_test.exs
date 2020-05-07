defmodule MeadowWeb.Schema.Mutation.AddWorksToCollectionTest do
  use MeadowWeb.ConnCase, acync: true
  use Wormwood.GQLCase

  alias Meadow.Data.Collections
  alias Meadow.Repo

  import Assertions

  load_gql(MeadowWeb.Schema, "test/gql/AddWorksToCollection.gql")

  test "should be a valid mutation" do
    collection = collection_fixture() |> Repo.preload(:works)
    assert collection.works |> Enum.empty?()

    works = [work_fixture(), work_fixture(), work_fixture()]
    work_ids = works |> Enum.map(& &1.id)

    result =
      query_gql(
        variables: %{"workIds" => work_ids, "collectionId" => collection.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    work_list =
      get_in(query_data, [:data, "addWorksToCollection", "works"])
      |> Enum.map(& &1["id"])

    assert_lists_equal(work_list, work_ids)

    collection = Collections.get_collection!(collection.id) |> Repo.preload(:works)
    assert collection.works |> length() == 3
  end
end
