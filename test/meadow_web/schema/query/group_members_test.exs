defmodule MeadowWeb.Schema.Query.GroupMembersTest do
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase
  use Meadow.LdapCase

  load_gql(MeadowWeb.Schema, "test/gql/GroupMembers.gql")

  describe "group membership query" do
    setup do
      Ldap.create_group("GRP1")
      create_ldap_users(["abc123"])
      Ldap.add_user("abc123", "GRP1")
      :ok
    end

    test "should be a valid query" do
      result =
        query_gql(
          variables: %{"groupName" => "GRP1"},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      users = get_in(query_data, [:data, "groupMembers"])
      assert length(users) == 1
    end
  end
end
