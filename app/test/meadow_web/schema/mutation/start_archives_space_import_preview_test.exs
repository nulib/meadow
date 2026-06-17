defmodule MeadowWeb.Schema.Mutation.StartArchivesSpaceImportPreviewTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace.{Client, MockServer, PreviewStore}

  load_gql(MeadowWeb.Schema, "test/gql/StartArchivesSpaceImportPreview.gql")

  setup do
    MockServer.reset()
    Client.invalidate_session()

    case start_supervised(PreviewStore) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    # The mutation returns immediately, but the background task still samples the
    # resource; keep it off the network and away from the real agent.
    Application.put_env(:meadow, :archives_space_image_store, fn _uri, _key -> :ok end)

    Application.put_env(:meadow, :archives_space_preview_agent, fn _samples, _token ->
      {:ok, 0.0}
    end)

    on_exit(fn ->
      Application.delete_env(:meadow, :archives_space_image_store)
      Application.delete_env(:meadow, :archives_space_preview_agent)
    end)

    resource = MockServer.create_resource(2, %{"title" => "Berkeley Folk Music Festival Records"})

    {:ok, %{resource: resource}}
  end

  test "starts a preview and returns a pending token", %{resource: resource} do
    assert {:ok, query_data} =
             query_gql(
               variables: %{"resourceUri" => resource["uri"]},
               context: gql_context()
             )

    preview = get_in(query_data, [:data, "archivesSpaceStartImportPreview"])

    assert preview["token"] != nil
    assert preview["status"] == "PENDING"
    assert preview["previews"] == []
  end

  test "is not authorized for non-supermanager users", %{resource: resource} do
    assert {:ok, query_data} =
             query_gql(
               variables: %{"resourceUri" => resource["uri"]},
               context: gql_context(%{role: :manager})
             )

    assert [%{message: message}] = query_data[:errors]
    assert message =~ "Not authorized"
  end

  test "rejects resources that already link to Digital Collections", %{resource: resource} do
    digital_object =
      MockServer.create_digital_object(2, %{
        "file_versions" => [
          %{"file_uri" => "https://n2t.net/ark:/81985/n2t14wd6q"}
        ]
      })

    MockServer.create_archival_object(2, %{
      "level" => "file",
      "display_string" => "Already linked object",
      "resource" => %{"ref" => resource["uri"]},
      "instances" => [MockServer.digital_object_instance(digital_object)]
    })

    assert {:ok, query_data} =
             query_gql(
               variables: %{"resourceUri" => resource["uri"]},
               context: gql_context()
             )

    assert [%{message: message}] = query_data[:errors]
    assert message =~ "already contains digital object links"
  end
end
