defmodule Meadow.ArchivesSpace.SyncTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, MockServer, Sync}
  alias Meadow.Data.{FileSets, Works}

  setup do
    MockServer.reset()
    Client.invalidate_session()

    archivist_note = %{
      "jsonmodel_type" => "note_multipart",
      "type" => "scopecontent",
      "label" => "Processing note",
      "subnotes" => [%{"content" => "written by an archivist"}]
    }

    archival_object =
      MockServer.create_archival_object(2, %{
        "title" => "Original Title",
        "notes" => [archivist_note],
        "subjects" => [%{"ref" => "/subjects/999"}]
      })

    work =
      work_fixture(%{
        descriptive_metadata: %{
          title: "Meadow Title",
          description: ["A description from Meadow"],
          subject: [%{term: "mock1:result1", role: %{id: "TOPICAL", scheme: "subject_role"}}]
        }
      })

    {:ok, link} = ArchivesSpace.link_work(work, archival_object["uri"])

    {:ok, %{work: work, archival_object: archival_object, link: link, note: archivist_note}}
  end

  describe "sync_work/1" do
    test "pushes the work's metadata to the archival object", %{
      work: work,
      archival_object: %{"uri" => uri},
      note: archivist_note
    } do
      assert {:ok, link} = Sync.sync_work(work.id)
      assert link.sync_status == :synced
      assert link.sync_error |> is_nil()
      refute link.last_synced_at |> is_nil()

      record = MockServer.get_record(uri)
      assert record["title"] == "Meadow Title"

      assert archivist_note in record["notes"]
      assert [meadow_note] = Enum.filter(record["notes"], &(&1["label"] == "Synced from Meadow"))
      assert [%{"content" => "A description from Meadow"}] = meadow_note["subnotes"]
    end

    test "finds or creates subject records and links them", %{
      work: work,
      archival_object: %{"uri" => uri}
    } do
      assert {:ok, _link} = Sync.sync_work(work.id)

      record = MockServer.get_record(uri)
      refs = Enum.map(record["subjects"], & &1["ref"])
      assert "/subjects/999" in refs

      [new_ref] = refs -- ["/subjects/999"]
      assert MockServer.get_record(new_ref)["authority_id"] == "mock1:result1"
      assert [%{"term" => "First Result"}] = MockServer.get_record(new_ref)["terms"]
    end

    test "creates a digital object instance pointing back at the work", %{
      work: work,
      archival_object: %{"uri" => uri}
    } do
      assert {:ok, link} = Sync.sync_work(work.id)
      assert link.digital_object_uri

      digital_object = MockServer.get_record(link.digital_object_uri)
      assert digital_object["digital_object_id"] == work.id
      assert [%{"file_uri" => file_uri}] = digital_object["file_versions"]
      assert file_uri =~ work.id

      record = MockServer.get_record(uri)
      assert [instance] = record["instances"]
      assert instance["digital_object"]["ref"] == link.digital_object_uri
    end

    test "is idempotent across repeated syncs", %{work: work, archival_object: %{"uri" => uri}} do
      assert {:ok, link} = Sync.sync_work(work.id)
      assert {:ok, resynced} = Sync.sync_work(work.id)

      assert resynced.digital_object_uri == link.digital_object_uri

      record = MockServer.get_record(uri)
      assert Enum.count(record["instances"]) == 1
      assert Enum.count(record["notes"], &(&1["label"] == "Synced from Meadow")) == 1
      assert Enum.count(record["subjects"]) == 2
    end

    test "records sync failures on the link", %{work: work, link: link} do
      {:ok, link} =
        ArchivesSpace.update_link(link, %{
          archives_space_uri: "/repositories/2/archival_objects/404404"
        })

      assert {:error, _reason} = Sync.sync_work(work.id)

      link = ArchivesSpace.get_link!(link.id)
      assert link.sync_status == :error
      assert link.sync_error =~ "404"
    end

    test "is a noop for unlinked works" do
      assert Sync.sync_work(work_fixture().id) == :noop
      assert Sync.sync_work(Ecto.UUID.generate()) == :noop
    end
  end

  describe "digital object components" do
    setup %{work: work} do
      access = %{id: "A", scheme: "FILE_SET_ROLE"}

      fs1 =
        file_set_fixture(%{
          work_id: work.id,
          rank: 0,
          role: access,
          core_metadata: %{label: "Page 1", original_filename: "p1.tif", location: "s3://x/p1.tif"},
          derivatives: %{"pyramid_tiff" => "s3://pyr/p1.tif"}
        })

      {:ok, _} =
        FileSets.create_annotation(fs1, %{
          type: "transcription",
          status: "completed",
          content: "Dear John"
        })

      fs2 =
        file_set_fixture(%{
          work_id: work.id,
          rank: 1,
          role: access,
          core_metadata: %{label: "Page 2", original_filename: "p2.tif", location: "s3://x/p2.tif"}
        })

      {:ok, %{fs1: fs1, fs2: fs2}}
    end

    test "creates one component per access file set, with the transcription note", %{
      work: work,
      fs1: fs1,
      fs2: fs2
    } do
      assert {:ok, link} = Sync.sync_work(work.id)

      components = MockServer.list_digital_object_components(link.digital_object_uri)
      assert length(components) == 2

      by_id = Map.new(components, &{&1["component_id"], &1})

      c1 = by_id[fs1.id]
      assert c1["label"] == "Page 1"
      assert c1["position"] == 0
      assert [%{"use_statement" => "image-service"}] = c1["file_versions"]
      assert [note] = c1["notes"]
      assert note["label"] == "Synced from Meadow"
      assert note["content"] == ["Dear John"]

      c2 = by_id[fs2.id]
      assert c2["position"] == 1
      assert c2["notes"] == []
    end

    test "is idempotent and removes components for deleted file sets", %{
      work: work,
      fs1: fs1,
      fs2: fs2
    } do
      assert {:ok, link} = Sync.sync_work(work.id)
      assert {:ok, _} = Sync.sync_work(work.id)

      components = MockServer.list_digital_object_components(link.digital_object_uri)
      assert length(components) == 2
      c1 = Enum.find(components, &(&1["component_id"] == fs1.id))
      assert Enum.count(c1["notes"], &(&1["label"] == "Synced from Meadow")) == 1

      Repo.delete(fs2)
      assert {:ok, _} = Sync.sync_work(work.id)

      remaining = MockServer.list_digital_object_components(link.digital_object_uri)
      assert [only] = remaining
      assert only["component_id"] == fs1.id
    end

    test "preserves an archivist-created component", %{work: work} do
      assert {:ok, link} = Sync.sync_work(work.id)

      MockServer.seed(%{
        "uri" => "/repositories/2/digital_object_components/9999",
        "jsonmodel_type" => "digital_object_component",
        "component_id" => "ARCHIVIST-1",
        "digital_object" => %{"ref" => link.digital_object_uri},
        "lock_version" => 0
      })

      assert {:ok, _} = Sync.sync_work(work.id)

      components = MockServer.list_digital_object_components(link.digital_object_uri)
      assert Enum.any?(components, &(&1["component_id"] == "ARCHIVIST-1"))
    end
  end

  describe "broadened metadata" do
    test "creates linked agents and a creation date on the archival object" do
      archival_object = MockServer.create_archival_object(2, %{"title" => "Agented"})

      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Agented Work",
            creator: [%{term: "mock1:result1"}],
            date_created: [%{edtf: "1965", humanized: "1965"}]
          }
        })

      {:ok, _link} = ArchivesSpace.link_work(work, archival_object["uri"])

      assert {:ok, _} = Sync.sync_work(work.id)

      record = MockServer.get_record(archival_object["uri"])

      assert [agent] = record["linked_agents"]
      assert agent["role"] == "creator"
      assert MockServer.get_record(agent["ref"])["jsonmodel_type"] == "agent_person"

      assert [date] = Enum.filter(record["dates"], &(&1["label"] == "creation"))
      assert date["expression"] == "1965"
    end
  end

  describe "remove_work/1" do
    test "removes the digital object and the link but keeps the archival object", %{
      work: work,
      archival_object: %{"uri" => uri}
    } do
      {:ok, link} = Sync.sync_work(work.id)
      assert MockServer.get_record(link.digital_object_uri)

      Works.delete_work(work)
      assert {:ok, _} = Sync.remove_work(work.id)

      assert MockServer.get_record(link.digital_object_uri) |> is_nil()
      assert ArchivesSpace.get_link_for_work(work.id) |> is_nil()

      record = MockServer.get_record(uri)
      assert record["title"] == "Meadow Title"
      assert record["instances"] == []
    end

    test "removes the link even when no digital object was ever created", %{work: work} do
      assert {:ok, _} = Sync.remove_work(work.id)
      assert ArchivesSpace.get_link_for_work(work.id) |> is_nil()
    end

    test "is a noop for unlinked works" do
      assert Sync.remove_work(Ecto.UUID.generate()) == :noop
    end
  end
end
