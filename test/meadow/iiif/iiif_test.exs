defmodule Meadow.IIIFTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Config
  alias Meadow.Utils.Pairtree

  import ExUnit.DocTest

  doctest Meadow.IIIF, import: true

  @pyramid_bucket Config.pyramid_bucket()

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
      assert {:ok, %{status_code: 200}} = Meadow.IIIF.write_manifest(work.id)

      with {:ok, result} <- ExAws.S3.head_object(@pyramid_bucket, destination) |> ExAws.request() do
        assert result.status_code == 200
        assert result.headers |> Enum.member?({"Content-Type", "application/json"})
      end
    end
  end
end
