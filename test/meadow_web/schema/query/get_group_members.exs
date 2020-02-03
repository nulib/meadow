defmodule MeadowWeb.Schema.Query.GetGroupMembersTest do
  use Meadow.LdapCase
  use MeadowWeb.ConnCase
  use Wormwood.GQLCase

  alias Meadow.LdapHelpers

  import Meadow.LdapCase

  load_gql(MeadowWeb.Schema, "test/gql/GetGroupMembers.gql")

  test "should return group members" do
    user = user_fixture()
    user_dn = library_dn(user.username)
    group_name = "yyy111 Group"
    group_dn = library_dn(group_name)

    with {:ok, connection} <- Exldap.connect() do
      LdapHelpers.add_entry(connection, group_dn)
      LdapHelpers.add_membership(connection, group_dn, user_dn)
    end

    result =
      query_gql(
        variables: %{"id" => "CN=yyy111 Group,OU=NotMeadow,DC=library,DC=northwestern,DC=edu"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    members = get_in(query_data, [:data, "groupMembers"])

    assert Enum.member?(Enum.map(members, fn m -> m["name"] end), user.username)
  end
end
