defmodule MeadowWeb.Schema.Query.ArchivesSpaceResourceSearchTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.ArchivesSpace.{Client, MockServer}

  load_gql(MeadowWeb.Schema, "test/gql/ArchivesSpaceResourceSearch.gql")

  setup do
    MockServer.reset()
    Client.invalidate_session()

    on_exit(fn -> MockServer.reset() end)

    :ok
  end

  test "returns matching resources" do
    MockServer.create_resource(2, %{
      "title" => "Berkeley Folk Music Festival",
      "identifier" => "MS-63"
    })

    MockServer.create_resource(2, %{"title" => "University Archives"})

    result = query_gql(variables: %{"query" => "folk"}, context: gql_context())

    assert {:ok, query_data} = result

    search = get_in(query_data, [:data, "archivesSpaceResourceSearch"])
    assert search["totalHits"] == 1

    assert [%{"title" => "Berkeley Folk Music Festival", "identifier" => "MS-63"}] =
             search["results"]
  end

  test "returns a parent resource when an archival object matches" do
    resource =
      MockServer.create_resource(2, %{
        "title" => "John Cage scrapbooks",
        "identifier" => "abc123"
      })

    MockServer.create_archival_object(2, %{
      "title" => "John Cage: Composer, Vol. I, 1942 - 1946",
      "resource" => %{"ref" => resource["uri"]}
    })

    result = query_gql(variables: %{"query" => "Composer"}, context: gql_context())

    assert {:ok, query_data} = result

    search = get_in(query_data, [:data, "archivesSpaceResourceSearch"])
    assert search["totalHits"] == 1

    assert [
             %{
               "uri" => uri,
               "title" => "John Cage scrapbooks",
               "identifier" => "abc123"
             }
           ] = search["results"]

    assert uri == resource["uri"]
  end

  test "returns an empty result set when nothing matches" do
    assert {:ok, query_data} =
             query_gql(variables: %{"query" => "nonexistent"}, context: gql_context())

    assert get_in(query_data, [:data, "archivesSpaceResourceSearch", "results"]) == []
  end
end
