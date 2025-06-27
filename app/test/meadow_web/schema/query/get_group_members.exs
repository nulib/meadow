defmodule MeadowWeb.Schema.Query.GetGroupMembersTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetGroupMembers.gql")

  test "should return group members" do
    user_dn = test_users_dn(random_user(:administrator))
    group_dn = "CN=TestAdmins,OU=Departments,OU=test,DC=library,DC=northwestern,DC=edu"

    result =
      query_gql(
        variables: %{"id" => group_dn},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    members = get_in(query_data, [:data, "groupMembers"])

    assert Enum.member?(Enum.map(members, fn m -> m["name"] end), user.username)
  end
end
