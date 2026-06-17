defmodule MeadowWeb.Schema.Mutation.ImportArchivesSpaceResourceTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, MockServer}
  alias Meadow.Data.Schemas.Work

  import Assertions

  load_gql(MeadowWeb.Schema, "test/gql/ImportArchivesSpaceResource.gql")

  setup do
    MockServer.reset()
    Client.invalidate_session()

    resource = MockServer.create_resource(2, %{"title" => "Imported Via GraphQL"})

    MockServer.create_archival_object(2, %{
      "level" => "file",
      "display_string" => "Folder 1",
      "resource" => %{"ref" => resource["uri"]}
    })

    on_exit(fn -> MockServer.reset() end)

    {:ok, %{resource: resource}}
  end

  test "creates the linked collection and imports works in the background", %{
    resource: resource
  } do
    result =
      query_gql(
        variables: %{"resourceUri" => resource["uri"]},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    collection = get_in(query_data, [:data, "importArchivesSpaceResource"])
    assert collection["title"] == "Imported Via GraphQL"
    assert collection["findingAidUrl"] == resource["ead_location"]

    link = ArchivesSpace.get_collection_link_for_uri(resource["uri"])
    assert link.collection_id == collection["id"]

    assert_async(timeout: 2000) do
      assert from(w in Work, where: w.collection_id == ^collection["id"])
             |> Repo.aggregate(:count) == 1
    end
  end

  test "returns an error for an unknown resource" do
    assert {:ok, %{errors: [%{message: message}]}} =
             query_gql(
               variables: %{"resourceUri" => "/repositories/2/resources/999999"},
               context: gql_context()
             )

    assert message =~ "404"
  end

  test "rejects resources that already link to Digital Collections", %{resource: resource} do
    add_digital_collections_link(resource)

    assert {:ok, %{errors: [%{message: message}]}} =
             query_gql(
               variables: %{"resourceUri" => resource["uri"]},
               context: gql_context()
             )

    assert message =~ "already contains digital object links"
  end

  test "flags imported works for AI ingest for supermanager-capable users", %{
    resource: resource
  } do
    assert {:ok, query_data} =
             query_gql(
               variables: %{"resourceUri" => resource["uri"], "aiIngest" => true},
               context: gql_context(%{role: :administrator})
             )

    collection = get_in(query_data, [:data, "importArchivesSpaceResource"])

    assert_async(timeout: 2000) do
      work = Repo.one(from(w in Work, where: w.collection_id == ^collection["id"]))
      assert work && work.ai_ingest == true
    end
  end

  test "strips AI ingest for users below supermanager", %{resource: resource} do
    assert {:ok, query_data} =
             query_gql(
               variables: %{"resourceUri" => resource["uri"], "aiIngest" => true},
               context: gql_context(%{role: :manager})
             )

    collection = get_in(query_data, [:data, "importArchivesSpaceResource"])

    assert_async(timeout: 2000) do
      work = Repo.one(from(w in Work, where: w.collection_id == ^collection["id"]))
      assert work && work.ai_ingest == false
    end
  end

  describe "authorization" do
    test "editors are not authorized to import resources", %{resource: resource} do
      result =
        query_gql(
          variables: %{"resourceUri" => resource["uri"]},
          context: gql_context(%{role: :editor})
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end
  end

  defp add_digital_collections_link(resource) do
    digital_object =
      MockServer.create_digital_object(2, %{
        "file_versions" => [
          %{
            "file_uri" =>
              "https://dc.library.northwestern.edu/items/d2219b92-f014-405c-82c6-35a9dc2fb8c0"
          }
        ]
      })

    MockServer.create_archival_object(2, %{
      "level" => "file",
      "display_string" => "Already imported object",
      "resource" => %{"ref" => resource["uri"]},
      "instances" => [MockServer.digital_object_instance(digital_object)]
    })
  end
end
