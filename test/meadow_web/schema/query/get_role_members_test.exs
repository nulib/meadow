defmodule MeadowWeb.Schema.Query.GetRoleMembersTest do
  use Meadow.LdapCase
  use MeadowWeb.ConnCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetRoleMembers.gql")

  test "should return role members" do
    user = user_fixture()

    result =
      query_gql(
        variables: %{"id" => "CN=Users,OU=Meadow,DC=library,DC=northwestern,DC=edu"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    members = get_in(query_data, [:data, "roleMembers"])

    assert Enum.member?(Enum.map(members, fn m -> m["name"] end), user.username)
  end
end
