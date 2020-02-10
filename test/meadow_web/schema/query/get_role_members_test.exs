defmodule MeadowWeb.Schema.Query.GetRoleMembersTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  import Assertions

  load_gql(MeadowWeb.Schema, "test/gql/GetRoleMembers.gql")

  test "should return role members" do
    result =
      query_gql(
        variables: %{"id" => meadow_dn("Users")},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    members = get_in(query_data, [:data, "roleMembers"])

    assert_lists_equal(
      Enum.map(members, fn m -> m["name"] end),
      ["TestAdmins", "TestManagers"]
    )
  end
end
