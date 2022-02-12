defmodule MeadowWeb.Schema.Mutation.UpdateWorkTest do
  use Meadow.DataCase
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

  describe "authorization" do
    test "viewers are not authorized to update works" do
      work = work_fixture()
      collection = collection_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => work.id,
            "collection_id" => collection.id,
            "descriptive_metadata" => %{"title" => "Something"}
          },
          context: %{current_user: %{role: "User"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to update works" do
      work = work_fixture()
      collection = collection_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => work.id,
            "collection_id" => collection.id,
            "descriptive_metadata" => %{"title" => "Something"}
          },
          context: %{current_user: %{role: "Editor"}}
        )

      assert result.data["updateWork"]
    end
  end
end
