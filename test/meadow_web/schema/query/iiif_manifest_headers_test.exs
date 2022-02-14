defmodule MeadowWeb.Schema.Query.IiifManifestHeadersTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  use Meadow.S3Case

  alias Meadow.Config
  alias Meadow.IIIF
  alias Meadow.Utils.Pairtree

  @pyramid_bucket Config.pyramid_bucket()

  load_gql(MeadowWeb.Schema, "test/gql/IiifManifestHeadersQuery.gql")

  describe "iiifManifestHeaders query/1" do
    setup do
      work = work_fixture()
      destination = Pairtree.manifest_key(work.id)

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)

      {:ok, work: work, destination: destination}
    end

    test "should be a valid query", %{work: work, destination: destination} do
      assert {:ok, %{status_code: 200}} = IIIF.V2.write_manifest(work.id)

      result =
        query_gql(
          variables: %{"workId" => work.id},
          context: gql_context()
        )

      assert {:ok, query_data} = result
      work_id = get_in(query_data, [:data, "iiifManifestHeaders", "workId"])
      assert work_id == work.id

      with {:ok, result} <- ExAws.S3.head_object(@pyramid_bucket, destination) |> ExAws.request() do
        assert result.status_code == 200

        last_modified =
          result.headers
          |> Enum.into(%{})
          |> Map.get("Last-Modified")

        assert last_modified == get_in(query_data, [:data, "iiifManifestHeaders", "lastModified"])
      end
    end
  end
end
