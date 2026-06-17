defmodule Meadow.ArchivesSpace.TranscriptionSyncIntegrationTest do
  @moduledoc """
  Exercises the transcription → digital object component sync against a *real*
  ArchivesSpace instance rather than the in-process
  `Meadow.ArchivesSpace.MockServer`.

  This is the round-trip the mock-based `Meadow.ArchivesSpace.SyncTest` and
  `Meadow.Events.FileSets.TranscriptionSyncTest` assert, validated end to end
  against the real app: a transcription saved on an access file set of a work
  linked to an ArchivesSpace archival object becomes a `note_digital_object`,
  carrying the same content, on a `digital_object_component` under the digital
  object Meadow manages for that work.

  The full live wiring is exercised: saving the annotation is the only trigger,
  and the WAL listener (`Meadow.Events.FileSets.TranscriptionSync`) → rate-
  limited `Processor` → `Sync` path carries it the rest of the way. The
  `walex` moduletag runs the listener against the real (unsandboxed) database
  for this test, the same as `TranscriptionSyncTest`.

  Start the docker stack first (first boot can take 10+ minutes):

      make -C infrastructure/archivesspace wait

  Then run just this test:

      cd app && mix test --only archivesspace_integration

  It is excluded from the default suite via the `:archivesspace_integration`
  tag. The test seeds its own resource and archival object through the staff
  API; the digital object and its components are created by the sync itself.
  """
  use Meadow.DataCase

  import Assertions

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, Mapper}
  alias Meadow.Data.FileSets

  @moduletag :archivesspace_integration
  @moduletag timeout: 120_000
  @moduletag walex: [Meadow.Events.FileSets.TranscriptionSync]

  @api_url "http://localhost:8089"
  @transcription "Dear John,\n\nThis is the full text of the letter."

  setup do
    start_supervised!(Meadow.Events.Works.ArchivesSpace.Processor)

    previous = Application.get_env(:meadow, :archives_space)

    Application.put_env(:meadow, :archives_space, %{
      url: @api_url,
      user: "admin",
      password: "admin"
    })

    Client.invalidate_session()

    on_exit(fn ->
      Application.put_env(:meadow, :archives_space, previous)
      Client.invalidate_session()
    end)

    case Client.session_token() do
      {:ok, _token} ->
        :ok

      {:error, reason} ->
        flunk("""
        ArchivesSpace API not reachable at #{@api_url} (#{inspect(reason)}).
        Start it with `make -C infrastructure/archivesspace wait`.
        """)
    end
  end

  test "a saved transcription is mapped onto a digital object component in ArchivesSpace" do
    repo_uri = ensure_repository()
    resource_uri = create_resource(repo_uri)
    archival_object_uri = create_archival_object(repo_uri, resource_uri)

    # A linked Meadow work with an access file set, exactly as one would look
    # after ingest.
    work = work_fixture(%{descriptive_metadata: %{title: "Linked Letter"}})

    file_set =
      file_set_fixture(%{
        work_id: work.id,
        rank: 0,
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{label: "Page 1", original_filename: "p1.tif", location: "s3://x/p1.tif"}
      })

    {:ok, _link} = ArchivesSpace.link_work(work, archival_object_uri)

    # Saving a completed transcription is the only thing this test does to
    # trigger the sync. From here the live WAL listener picks up the insert and
    # drives Processor → Sync against the real ArchivesSpace.
    {:ok, _annotation} =
      FileSets.create_annotation(file_set, %{
        type: "transcription",
        status: "completed",
        content: @transcription
      })

    # The real digital object ends up with a component for the access file set,
    # keyed by the file set id, whose Meadow-labeled note holds the exact
    # transcription content. Allow generous time for WAL replication plus the
    # rate-limited round trip to a real ArchivesSpace.
    assert_async(timeout: 60_000, sleep_time: 500) do
      link = ArchivesSpace.get_link_for_work(work.id)
      assert link.sync_status == :synced
      assert link.digital_object_uri

      component =
        link.digital_object_uri
        |> fetch_components()
        |> Enum.find(&(&1["component_id"] == file_set.id))

      assert component, "expected a digital object component for the access file set"
      assert component["label"] == "Page 1"

      assert [note] = Enum.filter(component["notes"], &(&1["label"] == Mapper.note_label()))
      assert note["jsonmodel_type"] == "note_digital_object"
      assert note["content"] == [@transcription]
    end
  end

  # Walks the real digital object tree the same way `Sync.fetch_components`
  # does, returning the full component records.
  defp fetch_components(digital_object_uri) do
    {:ok, %{status: 200, body: root}} = Client.get(digital_object_uri <> "/tree/root")

    case root["waypoints"] do
      count when is_integer(count) and count > 0 ->
        Enum.flat_map(0..(count - 1), &waypoint_components(digital_object_uri, &1))

      _ ->
        []
    end
  end

  defp waypoint_components(digital_object_uri, offset) do
    {:ok, %{status: 200, body: nodes}} =
      Client.get(digital_object_uri <> "/tree/waypoint", params: [offset: offset])

    Enum.map(nodes, fn %{"uri" => uri} ->
      {:ok, record} = Client.get_record(uri)
      record
    end)
  end

  # Seeding helpers — minimal valid JSONModel records for a current
  # ArchivesSpace. A fresh instance has no user repository, so create one.

  defp ensure_repository do
    case Client.get("/repositories") do
      {:ok, %{status: 200, body: repos}} when is_list(repos) ->
        repos
        |> Enum.map(& &1["uri"])
        |> Enum.find(&(is_binary(&1) and Regex.match?(~r{^/repositories/\d+$}, &1)))
        |> case do
          nil -> create_repository()
          uri -> uri
        end

      _ ->
        create_repository()
    end
  end

  defp create_repository do
    {:ok, uri} =
      Client.create_record("/repositories", %{
        "jsonmodel_type" => "repository",
        "repo_code" => "meadow_int_#{unique()}",
        "name" => "Meadow Integration Tests"
      })

    uri
  end

  defp create_resource(repo_uri) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/resources", %{
        "jsonmodel_type" => "resource",
        "title" => "Meadow Integration #{unique()}",
        "id_0" => "MEADOW-#{unique()}",
        "level" => "collection",
        "publish" => true,
        "finding_aid_language" => "eng",
        "finding_aid_script" => "Latn",
        "lang_materials" => [
          %{
            "jsonmodel_type" => "lang_material",
            "language_and_script" => %{
              "jsonmodel_type" => "language_and_script",
              "language" => "eng"
            }
          }
        ],
        "dates" => [single_date()],
        "extents" => [
          %{
            "jsonmodel_type" => "extent",
            "portion" => "whole",
            "number" => "1",
            "extent_type" => "linear_feet"
          }
        ]
      })

    uri
  end

  defp create_archival_object(repo_uri, resource_uri) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/archival_objects", %{
        "jsonmodel_type" => "archival_object",
        "title" => "Integration Folder #{unique()}",
        "level" => "file",
        "publish" => true,
        "resource" => %{"ref" => resource_uri},
        "dates" => [single_date()]
      })

    uri
  end

  defp single_date do
    %{
      "jsonmodel_type" => "date",
      "date_type" => "single",
      "label" => "creation",
      "expression" => "1968"
    }
  end

  defp unique, do: System.unique_integer([:positive])
end
