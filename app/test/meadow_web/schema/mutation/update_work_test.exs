defmodule MeadowWeb.Schema.Mutation.UpdateWorkTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
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

  describe "identified free-text values" do
    setup do
      work = work_fixture(%{descriptive_metadata: %{title: "Test", description: ["Original"]}})
      [entry] = Works.get_work!(work.id).descriptive_metadata.description
      {:ok, %{work: work, entry: entry, collection: collection_fixture()}}
    end

    test "echoing an item's id preserves its identity through an edit", ctx do
      {:ok, result} =
        query_gql(
          variables: %{
            "id" => ctx.work.id,
            "collection_id" => ctx.collection.id,
            "descriptive_metadata" => %{
              "description" => [%{"id" => ctx.entry.id, "value" => "Edited"}]
            }
          },
          context: gql_context()
        )

      assert result.data["updateWork"]

      assert [%{id: id, value: "Edited"}] =
               Works.get_work!(ctx.work.id).descriptive_metadata.description

      assert id == ctx.entry.id
    end

    test "an id-less unchanged value keeps its id; a new value gets its own", ctx do
      {:ok, result} =
        query_gql(
          variables: %{
            "id" => ctx.work.id,
            "collection_id" => ctx.collection.id,
            "descriptive_metadata" => %{
              "description" => [%{"value" => "Original"}, %{"value" => "Added"}]
            }
          },
          context: gql_context()
        )

      assert result.data["updateWork"]

      assert [%{id: kept_id, value: "Original"}, %{value: "Added"}] =
               Works.get_work!(ctx.work.id).descriptive_metadata.description

      assert kept_id == ctx.entry.id
    end

    # `ValueEntryInput` is a typed input object, so a malformed item fails
    # GraphQL validation up front instead of quietly dropping the id and
    # reminting it on save.
    test "a mistyped entry field is a query error, not a silently dropped id", ctx do
      {:ok, result} =
        query_gql(
          variables: %{
            "id" => ctx.work.id,
            "collection_id" => ctx.collection.id,
            "descriptive_metadata" => %{
              "description" => [%{"id" => ctx.entry.id, "valu" => "Edited"}]
            }
          },
          context: gql_context()
        )

      assert %{errors: [%{message: message}]} = result
      assert message =~ "invalid value"

      # The work was not touched.
      assert [%{value: "Original"}] =
               Works.get_work!(ctx.work.id).descriptive_metadata.description
    end
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
          context: gql_context(%{role: :user})
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
          context: gql_context(%{role: :editor})
        )

      assert result.data["updateWork"]
    end
  end
end
