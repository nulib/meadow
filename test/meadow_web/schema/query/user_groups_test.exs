defmodule MeadowWeb.Schema.Query.UserGroupsTest do
  use MeadowWeb.ConnCase, async: false

  use Wormwood.GQLCase
  use Meadow.LdapCase

  load_gql(MeadowWeb.Schema, "test/gql/UserGroups.gql")

  describe "user groups query" do
    setup do
      Ldap.create_group("UG1")
      Ldap.create_group("UG2")
      create_ldap_users(["tu1"])
      create_ldap_users(["tu2"])
      Ldap.add_user("tu1", "UG1")
      Ldap.add_user("tu1", "UG2")
      Ldap.add_user("tu2", "UG2")

      :ok
    end

    test "should be a valid query" do
      result =
        query_gql(
          variables: %{"username" => "tu1"},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      groups = get_in(query_data, [:data, "userGroups"])
      assert length(groups) == 2
    end
  end
end
