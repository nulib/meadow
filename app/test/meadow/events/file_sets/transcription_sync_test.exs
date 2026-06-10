defmodule Meadow.Events.FileSets.TranscriptionSyncTest do
  use Meadow.DataCase, async: false

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, MockServer}
  alias Meadow.Data.FileSets

  import Assertions
  import Meadow.TestHelpers

  @moduletag walex: [Meadow.Events.FileSets.TranscriptionSync]

  describe "Meadow.Events.FileSets.TranscriptionSync" do
    setup do
      start_supervised!(Meadow.Events.Works.ArchivesSpace.Processor)
      MockServer.reset()
      Client.invalidate_session()

      archival_object = MockServer.create_archival_object(2, %{"title" => "Original Title"})
      work = work_fixture(%{descriptive_metadata: %{title: "Meadow Title"}})

      file_set =
        file_set_fixture(%{
          work_id: work.id,
          rank: 0,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{label: "Page 1", original_filename: "p1.tif", location: "s3://x/p1.tif"}
        })

      {:ok, link} = ArchivesSpace.link_work(work, archival_object["uri"])

      {:ok, %{work: work, file_set: file_set, link: link}}
    end

    test "completing a transcription syncs the linked work to ArchivesSpace", %{
      work: work,
      file_set: file_set
    } do
      {:ok, _annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "Dear John"
        })

      assert_async(timeout: 2000) do
        link = ArchivesSpace.get_link_for_work(work.id)
        assert link.sync_status == :synced

        components = MockServer.list_digital_object_components(link.digital_object_uri)
        component = Enum.find(components, &(&1["component_id"] == file_set.id))
        assert component
        assert [%{"content" => ["Dear John"]}] = component["notes"]
      end
    end

    test "a pending transcription does not trigger a sync", %{work: work, file_set: file_set} do
      {:ok, _annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      :timer.sleep(1000)
      assert %{sync_status: :linked} = ArchivesSpace.get_link_for_work(work.id)
    end

    test "transcriptions on unlinked works are ignored" do
      unlinked = work_fixture()

      file_set =
        file_set_fixture(%{work_id: unlinked.id, role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      {:ok, _annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "Hi"
        })

      :timer.sleep(1000)
      assert ArchivesSpace.get_link_for_work(unlinked.id) |> is_nil()
    end
  end
end
