defmodule MeadowWeb.Schema.Mutation.SetWorkImageTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.Works

  load_gql(MeadowWeb.Schema, "test/gql/SetWorkImage.gql")

  test "should be a valid mutation" do
    work =
      work_with_file_sets_fixture(3, %{}, %{
        derivatives: %{"pyramid_tiff" => "s3://fo/ob/ar-pyramid.tif"},
        role: %{id: "A", scheme: "FILE_SET_ROLE"}
      })

    expected_file_set = work.file_sets |> Enum.at(1)
    file_set_image = Meadow.Config.iiif_server_url() <> expected_file_set.id

    refute work.representative_image == file_set_image

    result =
      query_gql(
        variables: %{
          "work_id" => work.id,
          "file_set_id" => expected_file_set.id
        },
        context: gql_context()
      )

    assert {:ok, %{data: _} = query_data} = result

    work = Works.get_work!(work.id)
    assert work.representative_image == file_set_image

    url = get_in(query_data, [:data, "setWorkImage", "representativeImage"])
    assert url == file_set_image
  end

  describe "authorization" do
    test "viewers are not authorized to set work images" do
      work = work_with_file_sets_fixture(3, %{}, %{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      expected_file_set = work.file_sets |> Enum.at(1)

      {:ok, result} =
        query_gql(
          variables: %{
            "work_id" => work.id,
            "file_set_id" => expected_file_set.id
          },
          context: %{current_user: %{role: "User"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to set work images" do
      work = work_with_file_sets_fixture(3, %{}, %{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      expected_file_set = work.file_sets |> Enum.at(1)

      {:ok, result} =
        query_gql(
          variables: %{
            "work_id" => work.id,
            "file_set_id" => expected_file_set.id
          },
          context: %{current_user: %{role: "Editor"}}
        )

      assert result.data["setWorkImage"]
    end
  end
end
