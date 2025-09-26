defmodule MeadowWeb.Schema.Mutation.SetCollectionImageTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.Collections

  load_gql(MeadowWeb.Schema, "test/gql/SetCollectionImage.gql")

  test "should be a valid mutation" do
    collection = collection_fixture()

    works = [
      work_with_file_sets_fixture(1, %{collection_id: collection.id}, %{
        derivatives: %{"pyramid_tiff" => "s3://fo/ob/ar/1-pyramid.tif"},
        role: %{id: "A", scheme: "FILE_SET_ROLE"}
      }),
      work_with_file_sets_fixture(1, %{collection_id: collection.id}, %{
        derivatives: %{"pyramid_tiff" => "s3://fo/ob/ar/2-pyramid.tif"},
        role: %{id: "A", scheme: "FILE_SET_ROLE"}
      }),
      work_with_file_sets_fixture(1, %{collection_id: collection.id}, %{
        derivatives: %{"pyramid_tiff" => "s3://fo/ob/ar/3-pyramid.tif"},
        role: %{id: "A", scheme: "FILE_SET_ROLE"}
      })
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

    url =
      get_in(query_data, [
        :data,
        "setCollectionImage",
        "representativeWork",
        "representativeImage"
      ])

    assert get_in(query_data, [:data, "setCollectionImage", "works"])
           |> Enum.find(fn work -> Map.get(work, "id") == expected_work.id end)
           |> Map.get("representativeImage") == expected_work.representative_image

    assert url == expected_work.representative_image
  end

  describe "authorization" do
    test "viewers and editors are not authorized to set representative images" do
      collection = collection_fixture()
      work = work_with_file_sets_fixture(1, %{collection_id: collection.id})

      {:ok, result} =
        query_gql(
          variables: %{
            "collection_id" => collection.id,
            "work_id" => work.id
          },
          context: gql_context(%{role: :editor})
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "managers and above are authorized to set representative images" do
      collection = collection_fixture()
      work = work_with_file_sets_fixture(1, %{collection_id: collection.id})

      {:ok, result} =
        query_gql(
          variables: %{
            "collection_id" => collection.id,
            "work_id" => work.id
          },
          context: gql_context(%{role: :manager})
        )

      assert result.data["setCollectionImage"]
    end

    test "representative image can be cleared by setting to null" do
      collection = collection_fixture()
      work = work_with_file_sets_fixture(1, %{collection_id: collection.id})

      {:ok, collection} =
        Collections.update_collection(collection, %{representative_work_id: work.id})

      refute collection
             |> Map.get(:representative_work_id)
             |> is_nil()

      {:ok, result} =
        query_gql(
          variables: %{
            "collection_id" => collection.id,
            "work_id" => nil
          },
          context: gql_context(%{role: :manager})
        )

      assert result.data["setCollectionImage"]

      assert collection.id
             |> Collections.get_collection!()
             |> Map.get(:representative_work_id)
             |> is_nil()
    end
  end
end
