defmodule MeadowWeb.Resolvers.Data.SharedLinkTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateSharedLink.gql")

  test "should be a valid mutation" do
    result =
      query_gql(
        variables: %{"workId" => "1234"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    assert "1234" == get_in(query_data, [:data, "createSharedLink", "workId"])
  end
end
