defmodule Meadow.IIIF.ManifestListenerTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Config
  alias Meadow.IIIF.ManifestListener
  alias Meadow.Utils.Pairtree

  @pyramid_bucket Config.pyramid_bucket()

  describe "handle_notification/4" do
    test "writes a manifest to S3 when it receives a Postgres INSERT/UPDATE notification" do
      work = work_fixture()
      destination = Pairtree.manifest_key(work.id)
      ManifestListener.handle_notification(:works, :insert, %{id: work.id}, nil)

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end

    test "fails gracefully when work is not found" do
      assert {:noreply, nil} == ManifestListener.handle_notification(:works, :insert, %{id: Ecto.UUID.generate()}, nil)
    end

    test "ignores DELETE notification" do
      work = work_fixture()
      Repo.delete(work)
      ManifestListener.handle_notification(:works, :delete, %{id: work.id}, nil)
    end
  end
end
