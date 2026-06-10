defmodule Meadow.Events.Works.ArchivesSpaceTest do
  use Meadow.DataCase, async: false

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, MockServer}
  alias Meadow.Data.Works

  import Assertions
  import Meadow.TestHelpers

  @moduletag walex: [Meadow.Events.Works.ArchivesSpace]

  describe "Meadow.Events.Works.ArchivesSpace" do
    setup do
      start_supervised!(Meadow.Events.Works.ArchivesSpace.Processor)
      MockServer.reset()
      Client.invalidate_session()

      archival_object = MockServer.create_archival_object(2, %{"title" => "Original Title"})
      work = work_fixture(%{descriptive_metadata: %{title: "Meadow Title"}})
      {:ok, link} = ArchivesSpace.link_work(work, archival_object["uri"])

      {:ok, %{work: work, archival_object: archival_object, link: link}}
    end

    test "updating a synced field pushes the work to ArchivesSpace", %{
      work: work,
      archival_object: %{"uri" => uri}
    } do
      Works.update_work!(work, %{descriptive_metadata: %{title: "Updated Title"}})

      assert_async(timeout: 2000) do
        assert %{"title" => "Updated Title"} = MockServer.get_record(uri)
      end

      assert_async(timeout: 2000) do
        assert %{sync_status: :synced} = ArchivesSpace.get_link_for_work(work.id)
      end
    end

    test "publishing a work syncs the digital object", %{work: work} do
      work
      |> Works.update_work!(%{published: true, visibility: %{id: "OPEN", scheme: "visibility"}})

      assert_async(timeout: 2000) do
        link = ArchivesSpace.get_link_for_work(work.id)
        assert link.sync_status == :synced
        assert %{"publish" => true} = MockServer.get_record(link.digital_object_uri)
      end
    end

    test "changes to unsynced fields do not trigger a sync", %{
      work: work,
      archival_object: %{"uri" => uri}
    } do
      Works.update_work!(work, %{descriptive_metadata: %{box_name: ["Box 12"]}})

      :timer.sleep(1000)

      assert MockServer.get_record(uri)["title"] == "Original Title"
      assert %{sync_status: :linked} = ArchivesSpace.get_link_for_work(work.id)
    end

    test "updates to unlinked works are ignored", %{archival_object: %{"uri" => uri}} do
      unlinked = work_fixture()
      Works.update_work!(unlinked, %{descriptive_metadata: %{title: "No Link Here"}})

      :timer.sleep(1000)

      assert MockServer.get_record(uri)["title"] == "Original Title"
    end

    test "deleting a work removes its digital object but not the archival object", %{
      work: work,
      archival_object: %{"uri" => uri}
    } do
      Works.update_work!(work, %{descriptive_metadata: %{title: "Updated Title"}})

      assert_async(timeout: 2000) do
        link = ArchivesSpace.get_link_for_work(work.id)
        assert link.sync_status == :synced
        refute link.digital_object_uri |> is_nil()
      end

      digital_object_uri = ArchivesSpace.get_link_for_work(work.id).digital_object_uri

      Works.delete_work(Works.get_work!(work.id))

      assert_async(timeout: 2000) do
        assert MockServer.get_record(digital_object_uri) |> is_nil()
        assert ArchivesSpace.get_link_for_work(work.id) |> is_nil()
      end

      assert MockServer.get_record(uri)["title"] == "Updated Title"
    end
  end
end
