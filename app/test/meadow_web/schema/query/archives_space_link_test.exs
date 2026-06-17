defmodule MeadowWeb.Schema.Query.ArchivesSpaceLinkTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace

  load_gql(MeadowWeb.Schema, "test/gql/GetArchivesSpaceLink.gql")

  @archival_object_uri "/repositories/2/archival_objects/1234"

  test "returns the link for a linked work" do
    work = work_fixture()
    {:ok, link} = ArchivesSpace.link_work(work, @archival_object_uri)
    {:ok, _} = ArchivesSpace.mark_error(link, "did not work")

    result = query_gql(variables: %{"workId" => work.id}, context: gql_context())

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "archivesSpaceLink"])
    assert response["archivesSpaceUri"] == @archival_object_uri
    assert response["syncStatus"] == "ERROR"
    assert response["syncError"] == "did not work"
  end

  test "returns nil for unlinked works" do
    work = work_fixture()

    assert {:ok, query_data} =
             query_gql(variables: %{"workId" => work.id}, context: gql_context())

    assert get_in(query_data, [:data, "archivesSpaceLink"]) |> is_nil()
  end
end
