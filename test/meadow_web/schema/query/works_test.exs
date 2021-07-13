defmodule MeadowWeb.Schema.Query.WorksTest do
  defmodule All do
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query {
      works{
        id
      }
    }
    """)

    test "works query returns all works" do
      Enum.each(1..3, fn _ -> work_fixture() end)
      assert {:ok, %{data: query_data}} = query_gql(context: gql_context())

      assert [
               %{"id" => _},
               %{"id" => _},
               %{"id" => _}
             ] = query_data["works"]
    end
  end

  defmodule Limit do
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query($limit: Int!) {
      works(limit: $limit){
        id
      }
    }
    """)

    test "works query limits the number of works returned" do
      Enum.each(1..3, fn _ -> work_fixture() end)

      assert {:ok, %{data: query_data}} =
               query_gql(
                 variables: %{"limit" => 2},
                 context: gql_context()
               )

      assert [
               %{"id" => _},
               %{"id" => _}
             ] = query_data["works"]
    end
  end

  defmodule TitleMatch do
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query ($filter: WorkFilter!) {
      works(filter: $filter) {
        descriptiveMetadata{
          title
        }
      }
    }
    """)

    test "works query returns works filtered by title" do
      work_fixture(%{
        accession_number: "12345",
        descriptive_metadata: %{title: "This Title"}
      })

      work_fixture(%{
        accession_number: "123456",
        descriptive_metadata: %{title: "Other One"}
      })

      assert {:ok, %{data: query_data}} =
               query_gql(
                 variables: %{"filter" => %{"matching" => "This Title"}},
                 context: gql_context()
               )

      assert query_data["works"] ==
               [%{"descriptiveMetadata" => %{"title" => "This Title"}}]
    end
  end

  defmodule RepresentativeImage do
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase
    alias Meadow.Data.Works

    set_gql(MeadowWeb.Schema, """
    query {
      works{
        id
        representativeImage
      }
    }
    """)

    test "works query returns work with representative image" do
      work = work_fixture()

      %{id: image_id} =
        file_set_fixture(%{
          work_id: work.id,
          derivatives: %{pyramid_tiff: "s3://fo/ob/ar-pyramid.tif"}
        })

      work |> Works.update_work(%{representative_file_set_id: image_id})

      assert {:ok, %{data: query_data}} = query_gql(context: gql_context())
      expected = "#{Meadow.Config.iiif_server_url()}#{image_id}"

      assert [
               %{
                 "id" => _,
                 "representativeImage" => ^expected
               }
             ] = query_data["works"]
    end
  end
end
