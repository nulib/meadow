defmodule MeadowWeb.Schema.Mutation.SetCollectionImageTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.Collections

  load_gql(MeadowWeb.Schema, "test/gql/SetCollectionImage.gql")

  test "should be a valid mutation" do
    collection = collection_fixture()

    works = [
      work_with_file_sets_fixture(1, %{collection_id: collection.id}),
      work_with_file_sets_fixture(1, %{collection_id: collection.id}),
      work_with_file_sets_fixture(1, %{collection_id: collection.id})
    ]

    expected_work = works |> Enum.at(1)

    refute collection.representative_image == expected_work.representative_image

    result =
      query_gql(
        variables: %{
          "collection_id" => collection.id,
          "work_id" => expected_work.id
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collection = Collections.get_collection!(collection.id)
    assert collection.representative_image == expected_work.representative_image

    url = get_in(query_data, [:data, "setCollectionImage", "representativeImage"])

    assert get_in(query_data, [:data, "setCollectionImage", "works"])
           |> Enum.at(1)
           |> Map.get("representativeImage") == expected_work.representative_image

    assert url == expected_work.representative_image
  end
end
