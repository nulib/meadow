defmodule Meadow.IiifTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Config
  alias Meadow.Utils.Pairtree

  import ExUnit.DocTest

  doctest Meadow.IIIF, import: true

  @pyramid_bucket Config.pyramid_bucket()

  describe "write_manifest/1" do
    test "writes a IIIF manifest for a valid work to S3" do
      work = work_fixture()
      destination = Pairtree.manifest_key(work.id)

      assert {:ok, %{status_code: 200}} = Meadow.IIIF.write_manifest(work.id)

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end
  end
end
