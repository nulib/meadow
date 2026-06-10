defmodule MeadowWeb.Schema.Mutation.SyncWorkToArchivesSpaceTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, MockServer}

  load_gql(MeadowWeb.Schema, "test/gql/SyncWorkToArchivesSpace.gql")

  setup do
    MockServer.reset()
    Client.invalidate_session()

    on_exit(fn -> MockServer.reset() end)

    :ok
  end

  test "should be a valid mutation" do
    archival_object = MockServer.create_archival_object(2)
    work = work_fixture(%{descriptive_metadata: %{title: "Syncable Work"}})
    {:ok, _link} = ArchivesSpace.link_work(work, archival_object["uri"])

    result = query_gql(variables: %{"workId" => work.id}, context: gql_context())

    assert {:ok, query_data} = result

    link = get_in(query_data, [:data, "syncWorkToArchivesSpace"])
    assert link["syncStatus"] == "SYNCED"
    assert link["digitalObjectUri"]
    refute link["lastSyncedAt"] |> is_nil()

    assert MockServer.get_record(archival_object["uri"])["title"] == "Syncable Work"
  end

  test "returns an error for unlinked works" do
    work = work_fixture()

    assert {:ok, %{errors: [%{message: "Work is not linked to ArchivesSpace"}]}} =
             query_gql(variables: %{"workId" => work.id}, context: gql_context())
  end
end
