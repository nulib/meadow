defmodule Meadow.ArchivesSpace.ImporterIntegrationTest do
  @moduledoc """
  Exercises the importer against a *real* ArchivesSpace instance rather than
  the in-process `Meadow.ArchivesSpace.MockServer`.

  Start the docker stack first (first boot can take 10+ minutes):

      make -C infrastructure/archivesspace wait

  Then run just this test:

      cd app && mix test --only archivesspace_integration

  It is excluded from the default suite via the `:archivesspace_integration`
  tag. The test seeds its own resource, archival object, and digital object
  through the staff API, so it needs no manual data setup. S3 uploads and the
  processing pipeline are short-circuited through the importer's seams, so the
  only external dependency is the ArchivesSpace app itself.
  """
  use Meadow.DataCase

  @moduletag :archivesspace_integration
  @moduletag timeout: 120_000

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, Importer}

  @api_url "http://localhost:8089"
  # Reuse the existing image fixture's name so the created file set looks like
  # a real Meadow ingest; the bytes themselves are never fetched here because
  # the image store is stubbed below.
  @image_filename "coffee.tif"
  @file_uri "https://meadow.test/fixtures/#{@image_filename}"

  setup do
    previous = Application.get_env(:meadow, :archives_space)

    Application.put_env(:meadow, :archives_space, %{
      url: @api_url,
      user: "admin",
      password: "admin"
    })

    Client.invalidate_session()

    test_pid = self()

    # Keep the test's only external dependency the ArchivesSpace app: record
    # which images would be stored and which file sets would be sent to the
    # pipeline instead of touching S3 or SQS.
    Application.put_env(:meadow, :archives_space_image_store, fn uri, _key ->
      send(test_pid, {:stored, uri})
      :ok
    end)

    Application.put_env(:meadow, :archives_space_pipeline_starter, fn file_set ->
      send(test_pid, {:kickoff, file_set.id})
      :ok
    end)

    on_exit(fn ->
      Application.put_env(:meadow, :archives_space, previous)
      Application.delete_env(:meadow, :archives_space_image_store)
      Application.delete_env(:meadow, :archives_space_pipeline_starter)
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

  test "imports a real resource, its archival object, and its digital object image" do
    repo_uri = ensure_repository()
    resource_uri = create_resource(repo_uri)
    digital_object_uri = create_digital_object(repo_uri)
    archival_object_uri = create_archival_object(repo_uri, resource_uri, digital_object_uri)

    assert {:ok, summary} = Importer.import_resource(resource_uri)

    # The resource became a linked collection
    assert summary.collection.title =~ "Meadow Integration"
    assert ArchivesSpace.get_collection_link_for_uri(resource_uri)

    # The file-level archival object became a linked work
    assert ArchivesSpace.work_linked_to_uri?(archival_object_uri)

    # ...and its digital object image became an access file set
    work = Enum.find(summary.created, &(&1.file_sets != []))
    assert work, "expected a created work with a file set from the digital object"
    assert [file_set] = work.file_sets
    assert file_set.role.id == "A"
    assert file_set.core_metadata.original_filename == @image_filename

    # The real digital object's file_version was resolved and routed to the
    # pipeline (both via the importer's stubbed seams)
    assert_received {:stored, @file_uri}
    assert_received {:kickoff, _file_set_id}
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
        "ead_location" => "https://findingaids.example.edu/meadow-#{unique()}",
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

  defp create_digital_object(repo_uri) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/digital_objects", %{
        "jsonmodel_type" => "digital_object",
        "digital_object_id" => "meadow-int-#{unique()}",
        "title" => "Meadow Integration Image",
        "publish" => true,
        "file_versions" => [
          %{
            "jsonmodel_type" => "file_version",
            "file_uri" => @file_uri,
            "publish" => true,
            "use_statement" => "image-service"
          }
        ]
      })

    uri
  end

  defp create_archival_object(repo_uri, resource_uri, digital_object_uri) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/archival_objects", %{
        "jsonmodel_type" => "archival_object",
        "title" => "Integration Folder #{unique()}",
        "level" => "file",
        "publish" => true,
        "resource" => %{"ref" => resource_uri},
        "dates" => [single_date()],
        "instances" => [
          %{
            "jsonmodel_type" => "instance",
            "instance_type" => "digital_object",
            "digital_object" => %{"ref" => digital_object_uri}
          }
        ]
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
