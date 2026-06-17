defmodule Meadow.ArchivesSpace.ImporterTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, Importer, MockServer}
  alias Meadow.Data.Collections

  setup do
    MockServer.reset()
    Client.invalidate_session()

    resource =
      MockServer.create_resource(2, %{
        "title" => "Berkeley Folk Music Festival Records",
        "notes" => [
          %{
            "jsonmodel_type" => "note_multipart",
            "type" => "scopecontent",
            "subnotes" => [%{"content" => "Posters, photographs, and recordings."}]
          }
        ]
      })

    subject =
      MockServer.seed(%{
        "uri" => "/subjects/55",
        "jsonmodel_type" => "subject",
        "authority_id" => "mock1:result1",
        "source" => "local",
        "terms" => [%{"term" => "First Result", "term_type" => "topical"}]
      })

    series =
      MockServer.create_archival_object(2, %{
        "level" => "series",
        "title" => "Series I: Posters",
        "resource" => %{"ref" => resource["uri"]}
      })

    # Three file-level children of the series; the mock waypoint size is 2,
    # so reading them exercises waypoint pagination
    files =
      1..3
      |> Enum.map(fn n ->
        MockServer.create_archival_object(2, %{
          "level" => "file",
          "display_string" => "Poster #{n}, 1968",
          "resource" => %{"ref" => resource["uri"]},
          "parent" => %{"ref" => series["uri"]},
          "subjects" => [%{"ref" => subject["uri"]}],
          "notes" => [
            %{
              "jsonmodel_type" => "note_multipart",
              "type" => "scopecontent",
              "subnotes" => [%{"content" => "Description of poster #{n}"}]
            }
          ]
        })
      end)

    item =
      MockServer.create_archival_object(2, %{
        "level" => "item",
        "display_string" => "Festival program, 1968",
        "resource" => %{"ref" => resource["uri"]}
      })

    {:ok, %{resource: resource, series: series, files: files, item: item}}
  end

  describe "import_resource/2" do
    test "creates a linked collection from the resource", %{resource: resource} do
      assert {:ok, %{collection: collection}} = Importer.import_resource(resource["uri"])

      assert collection.title == "Berkeley Folk Music Festival Records"
      assert collection.description == "Posters, photographs, and recordings."
      assert collection.finding_aid_url == resource["ead_location"]

      link = ArchivesSpace.get_link_for_collection(collection.id)
      assert link.archives_space_uri == resource["uri"]
    end

    test "creates linked works for file- and item-level archival objects", %{
      resource: resource,
      series: series,
      files: files,
      item: item
    } do
      assert {:ok, summary} = Importer.import_resource(resource["uri"])

      assert length(summary.created) == 4
      assert summary.errors == []

      # the series is walked but not imported at the default levels
      assert series["uri"] in summary.skipped

      for ao <- [item | files] do
        link =
          Repo.get_by(Meadow.Data.Schemas.ArchivesSpaceLink, archives_space_uri: ao["uri"])

        assert link, "expected a link for #{ao["uri"]}"
        assert link.ref_id == ao["ref_id"]

        work = Meadow.Data.Works.get_work!(link.work_id)
        assert work.collection_id == summary.collection.id
        assert work.accession_number == "aspace:" <> ao["ref_id"]
        assert work.published == false
        assert work.visibility.id == "RESTRICTED"
        assert work.descriptive_metadata.title == ao["display_string"]
      end
    end

    test "pulls notes and resolvable subjects into descriptive metadata", %{
      resource: resource,
      files: [file | _]
    } do
      assert {:ok, summary} = Importer.import_resource(resource["uri"])

      work =
        Enum.find(summary.created, &(&1.descriptive_metadata.title == file["display_string"]))

      assert work.descriptive_metadata.description == ["Description of poster 1"]
      assert [subject] = work.descriptive_metadata.subject
      assert subject.term.id == "mock1:result1"
      assert subject.role.id == "TOPICAL"
    end

    test "skips subjects without resolvable authority ids", %{resource: resource, item: item} do
      MockServer.seed(%{
        "uri" => "/subjects/77",
        "jsonmodel_type" => "subject",
        "source" => "local",
        "terms" => [%{"term" => "Local-only subject", "term_type" => "topical"}]
      })

      MockServer.seed(Map.put(item, "subjects", [%{"ref" => "/subjects/77"}]))

      assert {:ok, summary} = Importer.import_resource(resource["uri"])

      work =
        Enum.find(summary.created, &(&1.descriptive_metadata.title == item["display_string"]))

      assert work.descriptive_metadata.subject == []
    end

    test "re-importing skips already-linked archival objects and reuses the collection", %{
      resource: resource
    } do
      assert {:ok, first} = Importer.import_resource(resource["uri"])
      assert length(first.created) == 4

      assert {:ok, second} = Importer.import_resource(resource["uri"])
      assert second.created == []
      assert length(second.skipped) == 5
      assert second.collection.id == first.collection.id
      assert [_only_one] = Collections.list_collections()
    end

    test "collects per-record errors without aborting", %{resource: resource, files: [file | _]} do
      # A duplicate ref_id produces a duplicate accession number on import
      MockServer.create_archival_object(2, %{
        "level" => "file",
        "display_string" => "Duplicate accession",
        "ref_id" => file["ref_id"],
        "resource" => %{"ref" => resource["uri"]}
      })

      assert {:ok, summary} = Importer.import_resource(resource["uri"])

      assert length(summary.created) == 4
      assert [{_uri, reason}] = summary.errors
      assert reason =~ ~r/accession.number/i
    end

    test "returns an error for an unknown resource" do
      assert {:error, _reason} = Importer.import_resource("/repositories/2/resources/999999")
    end

    test "flags created works for AI ingest when requested", %{resource: resource} do
      assert {:ok, summary} = Importer.import_resource(resource["uri"], ai_ingest: true)
      assert summary.created != []
      assert Enum.all?(summary.created, & &1.ai_ingest)
    end

    test "does not flag works for AI ingest by default", %{resource: resource} do
      assert {:ok, summary} = Importer.import_resource(resource["uri"])
      assert Enum.all?(summary.created, &(&1.ai_ingest == false))
    end

    test "ingests digital object images as access file sets and starts the pipeline", %{
      resource: resource,
      item: item
    } do
      Application.put_env(:meadow, :archives_space_image_store, fn _uri, _key -> :ok end)
      test_pid = self()

      Application.put_env(:meadow, :archives_space_pipeline_starter, fn file_set ->
        send(test_pid, {:kickoff, file_set.id})
        :ok
      end)

      on_exit(fn ->
        Application.delete_env(:meadow, :archives_space_image_store)
        Application.delete_env(:meadow, :archives_space_pipeline_starter)
      end)

      digital_object =
        MockServer.create_digital_object(2, %{
          "file_versions" => [
            %{"file_uri" => "https://images.example.edu/program.tif", "publish" => true}
          ]
        })

      MockServer.seed(
        Map.put(item, "instances", [MockServer.digital_object_instance(digital_object)])
      )

      assert {:ok, summary} = Importer.import_resource(resource["uri"])

      work =
        Enum.find(summary.created, &(&1.descriptive_metadata.title == item["display_string"]))

      assert [file_set] = work.file_sets
      assert file_set.role.id == "A"
      assert file_set.core_metadata.original_filename == "program.tif"
      assert file_set.core_metadata.location =~ ~r{/archivesspace/.*/program\.tif$}
      assert_received {:kickoff, _file_set_id}
    end

    test "sets the work's representative image from the is_representative file version", %{
      resource: resource,
      item: item
    } do
      Application.put_env(:meadow, :archives_space_image_store, fn _uri, _key -> :ok end)

      on_exit(fn ->
        Application.delete_env(:meadow, :archives_space_image_store)
        Application.delete_env(:meadow, :archives_space_pipeline_starter)
      end)

      Application.put_env(:meadow, :archives_space_pipeline_starter, fn _file_set -> :ok end)

      digital_object =
        MockServer.create_digital_object(2, %{
          "file_versions" => [
            %{"file_uri" => "https://images.example.edu/first.tif"},
            %{
              "file_uri" => "https://images.example.edu/second.tif",
              "is_representative" => true
            }
          ]
        })

      MockServer.seed(
        Map.put(item, "instances", [MockServer.digital_object_instance(digital_object)])
      )

      assert {:ok, summary} = Importer.import_resource(resource["uri"])

      work =
        Enum.find(summary.created, &(&1.descriptive_metadata.title == item["display_string"]))

      reloaded =
        work.id |> Meadow.Data.Works.get_work!() |> Repo.preload(:representative_file_set)

      assert reloaded.representative_file_set.core_metadata.original_filename == "second.tif"
    end
  end

  describe "import_resource_async/2" do
    import Assertions

    test "returns the collection immediately and imports works in the background", %{
      resource: resource
    } do
      assert {:ok, collection} = Importer.import_resource_async(resource["uri"])
      assert collection.title == "Berkeley Folk Music Festival Records"

      assert_async(timeout: 2000) do
        assert from(w in Meadow.Data.Schemas.Work, where: w.collection_id == ^collection.id)
               |> Repo.aggregate(:count) == 4
      end
    end

    test "returns an error without starting a task for an unknown resource" do
      assert {:error, _reason} =
               Importer.import_resource_async("/repositories/2/resources/999999")
    end
  end
end
