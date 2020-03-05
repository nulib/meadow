defmodule MeadowWeb.Schema.Mutation.UpdateWorkTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Data.Works
  alias Meadow.Repo

  load_gql(MeadowWeb.Schema, "test/gql/UpdateWork.gql")

  test "should be a valid mutation" do
    work = work_fixture()
    collection = collection_fixture() |> Repo.preload(:works)
    assert collection.works |> Enum.empty?()

    result =
      query_gql(
        variables: %{
          "id" => work.id,
          "collection_id" => collection.id,
          "visibility" => "RESTRICTED",
          "descriptive_metadata" => %{"title" => "Something"}
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    title = get_in(query_data, [:data, "updateWork", "descriptiveMetadata", "title"])
    assert title == "Something"

    work = Works.get_work!(work.id) |> Repo.preload(:collection)
    assert work.collection.id == collection.id
  end
end
