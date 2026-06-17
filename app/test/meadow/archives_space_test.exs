defmodule Meadow.ArchivesSpaceTest do
  use Meadow.DataCase

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, MockServer}
  alias Meadow.Data.Schemas.ArchivesSpaceLink

  @archival_object_uri "/repositories/2/archival_objects/1234"
  @resource_uri "/repositories/3/resources/42"

  describe "linking" do
    test "link_work/3 creates a link to an archival object" do
      work = work_fixture()

      assert {:ok, %ArchivesSpaceLink{} = link} =
               ArchivesSpace.link_work(work, @archival_object_uri, %{ref_id: "ref123"})

      assert link.work_id == work.id
      assert link.archives_space_uri == @archival_object_uri
      assert link.repository_id == 2
      assert link.ref_id == "ref123"
      assert link.sync_status == :linked
      assert ArchivesSpace.get_link_for_work(work).id == link.id
    end

    test "link_collection/3 creates a link to a resource" do
      collection = collection_fixture()

      assert {:ok, %ArchivesSpaceLink{} = link} =
               ArchivesSpace.link_collection(collection, @resource_uri)

      assert link.collection_id == collection.id
      assert link.repository_id == 3
      assert ArchivesSpace.get_link_for_collection(collection).id == link.id
    end

    test "rejects malformed ArchivesSpace URIs" do
      work = work_fixture()

      assert {:error, changeset} = ArchivesSpace.link_work(work, "https://example.edu/nope")

      assert "must look like /repositories/:repo_id/archival_objects/:id" in errors_on(changeset).archives_space_uri
    end

    test "requires a work or collection target" do
      assert {:error, changeset} =
               ArchivesSpace.create_link(%{archives_space_uri: @archival_object_uri})

      assert "link must target a work or a collection" in errors_on(changeset).work_id
    end

    test "rejects links targeting both a work and a collection" do
      work = work_fixture()
      collection = collection_fixture()

      assert {:error, changeset} =
               ArchivesSpace.create_link(%{
                 work_id: work.id,
                 collection_id: collection.id,
                 archives_space_uri: @archival_object_uri
               })

      assert "link cannot target both a work and a collection" in errors_on(changeset).work_id
    end

    test "allows only one link per work" do
      work = work_fixture()
      assert {:ok, _} = ArchivesSpace.link_work(work, @archival_object_uri)

      assert {:error, changeset} =
               ArchivesSpace.link_work(work, "/repositories/2/archival_objects/5678")

      assert "has already been taken" in errors_on(changeset).work_id
    end

    test "allows only one work link per ArchivesSpace archival object" do
      assert {:ok, _} = ArchivesSpace.link_work(work_fixture(), @archival_object_uri)

      assert {:error, changeset} = ArchivesSpace.link_work(work_fixture(), @archival_object_uri)

      assert "has already been taken" in errors_on(changeset).archives_space_uri
    end

    test "allows only one collection link per ArchivesSpace resource" do
      assert {:ok, _} = ArchivesSpace.link_collection(collection_fixture(), @resource_uri)

      assert {:error, changeset} =
               ArchivesSpace.link_collection(collection_fixture(), @resource_uri)

      assert "has already been taken" in errors_on(changeset).archives_space_uri
    end

    test "unlink/1 removes the link" do
      work = work_fixture()
      {:ok, link} = ArchivesSpace.link_work(work, @archival_object_uri)

      assert {:ok, _} = ArchivesSpace.unlink(link)
      assert ArchivesSpace.get_link_for_work(work) |> is_nil()
    end
  end

  describe "sync status" do
    setup do
      work = work_fixture()
      {:ok, link} = ArchivesSpace.link_work(work, @archival_object_uri)
      {:ok, %{link: link}}
    end

    test "mark_pending/1", %{link: link} do
      assert {:ok, %{sync_status: :pending}} = ArchivesSpace.mark_pending(link)
    end

    test "mark_error/1 records the failure", %{link: link} do
      assert {:ok, updated} = ArchivesSpace.mark_error(link, "something went wrong")
      assert updated.sync_status == :error
      assert updated.sync_error == "something went wrong"

      assert {:ok, %{sync_error: "{:error, :nope}"}} =
               ArchivesSpace.mark_error(link, {:error, :nope})
    end

    test "mark_synced/1 clears errors and sets last_synced_at", %{link: link} do
      {:ok, link} = ArchivesSpace.mark_error(link, "transient failure")
      assert {:ok, updated} = ArchivesSpace.mark_synced(link)

      assert updated.sync_status == :synced
      assert updated.sync_error |> is_nil()
      refute updated.last_synced_at |> is_nil()
    end

    test "list_error_links/0 returns links in an error state", %{link: link} do
      assert ArchivesSpace.list_error_links() == []

      {:ok, _} = ArchivesSpace.mark_error(link, "boom")
      assert [%{sync_status: :error}] = ArchivesSpace.list_error_links()
    end
  end

  describe "validate_import_resource/1" do
    setup do
      MockServer.reset()
      Client.invalidate_session()

      resource = MockServer.create_resource(2, %{"title" => "Resource With Links"})

      {:ok, %{resource: resource}}
    end

    test "blocks resources with Digital Collections item links", %{resource: resource} do
      add_archival_object_with_file_uri(
        resource,
        "https://dc.library.northwestern.edu/items/d2219b92-f014-405c-82c6-35a9dc2fb8c0"
      )

      assert {:ok, validation} = ArchivesSpace.validate_import_resource(resource["uri"])
      refute validation.importable
      assert validation.blocked_count == 1
      assert [%{file_uri: file_uri}] = validation.blocked_samples
      assert file_uri =~ "dc.library.northwestern.edu/items"
    end

    test "blocks resources with n2t ARK links", %{resource: resource} do
      add_archival_object_with_file_uri(resource, "https://n2t.net/ark:/81985/n2t14wd6q")

      assert {:ok, validation} = ArchivesSpace.validate_import_resource(resource["uri"])
      refute validation.importable
      assert validation.blocked_count == 1
    end

    test "allows resources with image file links", %{resource: resource} do
      add_archival_object_with_file_uri(resource, "https://images.example.edu/poster.tif")

      assert {:ok, validation} = ArchivesSpace.validate_import_resource(resource["uri"])
      assert validation.importable
      assert validation.blocked_count == 0
    end
  end

  defp add_archival_object_with_file_uri(resource, file_uri) do
    digital_object =
      MockServer.create_digital_object(2, %{
        "file_versions" => [%{"file_uri" => file_uri}]
      })

    MockServer.create_archival_object(2, %{
      "level" => "file",
      "title" => "Linked Digital Object",
      "resource" => %{"ref" => resource["uri"]},
      "instances" => [MockServer.digital_object_instance(digital_object)]
    })
  end
end
