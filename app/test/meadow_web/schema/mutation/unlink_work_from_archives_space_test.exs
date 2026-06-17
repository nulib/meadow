defmodule MeadowWeb.Schema.Mutation.UnlinkWorkFromArchivesSpaceTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace

  load_gql(MeadowWeb.Schema, "test/gql/UnlinkWorkFromArchivesSpace.gql")

  @archival_object_uri "/repositories/2/archival_objects/1234"

  test "should be a valid mutation" do
    work = work_fixture()
    {:ok, _link} = ArchivesSpace.link_work(work, @archival_object_uri)

    result = query_gql(variables: %{"workId" => work.id}, context: gql_context())

    assert {:ok, query_data} = result
    assert get_in(query_data, [:data, "unlinkWorkFromArchivesSpace", "workId"]) == work.id
    assert ArchivesSpace.get_link_for_work(work.id) |> is_nil()
  end

  test "returns an error for unlinked works" do
    work = work_fixture()

    assert {:ok, %{errors: [%{message: "Work is not linked to ArchivesSpace"}]}} =
             query_gql(variables: %{"workId" => work.id}, context: gql_context())
  end
end
