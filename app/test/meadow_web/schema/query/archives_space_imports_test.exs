defmodule MeadowWeb.Schema.Query.ArchivesSpaceImportsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace

  load_gql(MeadowWeb.Schema, "test/gql/ArchivesSpaceImports.gql")

  @resource_uri "/repositories/2/resources/42"

  test "lists imported resources with their collection and work counts" do
    collection =
      collection_fixture(%{
        title: "Imported Finding Aid",
        finding_aid_url: "https://findingaids.example.edu/42"
      })

    {:ok, _link} = ArchivesSpace.link_collection(collection, @resource_uri)
    work_fixture(%{collection_id: collection.id})
    work_fixture(%{collection_id: collection.id})

    assert {:ok, query_data} = query_gql(context: gql_context())

    assert [import_record] = get_in(query_data, [:data, "archivesSpaceImports"])
    assert import_record["archivesSpaceUri"] == @resource_uri
    assert import_record["findingAidUrl"] == "https://findingaids.example.edu/42"
    assert import_record["workCount"] == 2
    assert import_record["collection"]["title"] == "Imported Finding Aid"
  end

  test "excludes work-only links" do
    work = work_fixture()
    {:ok, _} = ArchivesSpace.link_work(work, "/repositories/2/archival_objects/1")

    assert {:ok, query_data} = query_gql(context: gql_context())
    assert get_in(query_data, [:data, "archivesSpaceImports"]) == []
  end
end
