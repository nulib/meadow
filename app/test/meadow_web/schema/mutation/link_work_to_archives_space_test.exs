defmodule MeadowWeb.Schema.Mutation.LinkWorkToArchivesSpaceTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace

  load_gql(MeadowWeb.Schema, "test/gql/LinkWorkToArchivesSpace.gql")

  @archival_object_uri "/repositories/2/archival_objects/1234"

  test "should be a valid mutation" do
    work = work_fixture()

    result =
      query_gql(
        variables: %{
          "workId" => work.id,
          "archivesSpaceUri" => @archival_object_uri,
          "refId" => "ref123"
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    link = get_in(query_data, [:data, "linkWorkToArchivesSpace"])
    assert link["workId"] == work.id
    assert link["archivesSpaceUri"] == @archival_object_uri
    assert link["refId"] == "ref123"
    assert link["repositoryId"] == 2
    assert link["syncStatus"] == "LINKED"

    assert ArchivesSpace.get_link_for_work(work.id)
  end

  test "rejects invalid ArchivesSpace URIs" do
    work = work_fixture()

    assert {:ok, %{errors: [%{message: "Could not link work to ArchivesSpace"}]}} =
             query_gql(
               variables: %{"workId" => work.id, "archivesSpaceUri" => "not-a-uri"},
               context: gql_context()
             )
  end

  describe "authorization" do
    test "users are not authorized to link works" do
      work = work_fixture()

      result =
        query_gql(
          variables: %{"workId" => work.id, "archivesSpaceUri" => @archival_object_uri},
          context: gql_context(%{role: :user})
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end
  end
end
