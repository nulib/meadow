defmodule MeadowWeb.Schema.Mutation.AddGroupToRoleTest do
  use MeadowWeb.ConnCase, acync: true
  use Wormwood.GQLCase

  alias Meadow.Accounts.Ldap

  load_gql(MeadowWeb.Schema, "test/gql/AddGroupToRole.gql")

  describe "add group to role" do
    setup do
      group_id = "CN=TestAdmins,OU=Departments,OU=test,DC=library,DC=northwestern,DC=edu"
      role_id = meadow_dn("Editors")

      on_exit(fn ->
        Ldap.remove_member(role_id, group_id)
      end)

      {:ok, %{group_id: group_id, role_id: role_id}}
    end

    test "addGroupToRole", %{group_id: group_id, role_id: role_id} do
      result =
        query_gql(
          variables: %{"roleId" => role_id, "groupId" => group_id},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      assert get_in(query_data, [:data, "addGroupToRole", "message"]) == "OK"
    end
  end

  describe "add existing group to role" do
    setup do
      group_id = "CN=TestAdmins,OU=Departments,OU=test,DC=library,DC=northwestern,DC=edu"
      role_id = meadow_dn("Users")
      {:ok, %{group_id: group_id, role_id: role_id}}
    end

    test "addGroupToRole", %{group_id: group_id, role_id: role_id} do
      result =
        query_gql(
          variables: %{"roleId" => role_id, "groupId" => group_id},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      assert get_in(query_data, [:data, "addGroupToRole", "message"]) == "EXISTS"
    end
  end
end
