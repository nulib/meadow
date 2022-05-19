defmodule Meadow.IIIF.V2.Test do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.IIIF
  alias Meadow.Utils.Pairtree

  import ExUnit.DocTest

  doctest Meadow.IIIF.V2, import: true

  describe "write_manifest/1" do
    setup do
      work = work_fixture()
      destination = Pairtree.manifest_key(work.id)

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)

      {:ok, work: work, destination: destination}
    end

    test "writes a IIIF manifest for a valid work to S3", %{work: work, destination: destination} do
      assert {:ok, %{status_code: 200}} = IIIF.V2.write_manifest(work.id)

      with {:ok, result} <- ExAws.S3.head_object(@pyramid_bucket, destination) |> ExAws.request() do
        assert result.status_code == 200

        assert result.headers
               |> Enum.find(fn
                 {"Content-Type", "application/json"} -> true
                 {"content-type", "application/json"} -> true
                 _ -> false
               end)
      end
    end
  end
end
