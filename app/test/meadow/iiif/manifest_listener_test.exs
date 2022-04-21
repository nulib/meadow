defmodule Meadow.IIIF.V2.ManifestListenerTest do
  use Meadow.DataCase
  use Meadow.S3Case

  import ExUnit.CaptureLog

  alias Meadow.Config
  alias Meadow.IIIF.ManifestListener
  alias Meadow.Utils.Pairtree

  @pyramid_bucket Config.pyramid_bucket()

  describe "handle_notification/4" do
    test "writes a 2.x manifest to S3 when it receives a Postgres INSERT/UPDATE notification for an IMAGE work" do
      work = work_fixture(%{work_type: %{id: "IMAGE", scheme: "work_type"}})
      destination = Pairtree.manifest_key(work.id)

      assert capture_log(fn ->
               ManifestListener.handle_notification(:works, :insert, %{id: work.id}, nil)
             end)
             |> String.contains?("Writing IIIF 2.1.x manifest for image: #{work.id}")

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end

    test "writes a 3.x manifest to S3 when it receives a Postgres INSERT/UPDATE notification for an AUDIO or VIDEO work" do
      work = work_fixture(%{work_type: %{id: "VIDEO", scheme: "work_type"}})
      destination = Pairtree.manifest_v3_key(work.id)

      assert capture_log(fn ->
               ManifestListener.handle_notification(:works, :insert, %{id: work.id}, nil)
             end)
             |> String.contains?("Writing manifest IIIF 3.0.x for VIDEO: #{work.id}")

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end

    test "writes a 2.x manifest to S3 when it receives a Postgres DELETE notification for a fileset on an IMAGE work" do
      work = work_fixture(%{work_type: %{id: "IMAGE", scheme: "work_type"}})
      destination = Pairtree.manifest_key(work.id)

      assert capture_log(fn ->
               ManifestListener.handle_notification(:file_sets, :delete, %{id: work.id}, nil)
             end)
             |> String.contains?("Writing IIIF 2.1.x manifest for image: #{work.id}")

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end

    test "writes a 3.x manifest to S3 when it receives a Postgres DELETE notification for a fileset on an AUDIO or VIDEO work" do
      work = work_fixture(%{work_type: %{id: "VIDEO", scheme: "work_type"}})
      destination = Pairtree.manifest_v3_key(work.id)

      assert capture_log(fn ->
               ManifestListener.handle_notification(:file_sets, :delete, %{id: work.id}, nil)
             end)
             |> String.contains?("Writing manifest IIIF 3.0.x for VIDEO: #{work.id}")

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end

    test "fails gracefully when work is not found" do
      assert {:noreply, nil} ==
               ManifestListener.handle_notification(
                 :works,
                 :insert,
                 %{id: Ecto.UUID.generate()},
                 nil
               )
    end

    test "ignores DELETE notification" do
      work = work_fixture()
      Repo.delete(work)
      ManifestListener.handle_notification(:works, :delete, %{id: work.id}, nil)
    end
  end
end
