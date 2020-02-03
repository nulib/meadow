defmodule MeadowWeb.Schema.Mutation.AddGroupToRoleTest do
  use Meadow.LdapCase
  use MeadowWeb.ConnCase, acync: true
  use Wormwood.GQLCase

  alias Meadow.LdapHelpers

  import Meadow.LdapCase

  load_gql(MeadowWeb.Schema, "test/gql/AddGroupToRole.gql")

  test "adds a group to a role" do
    group_name = "The Group"
    group_id = library_dn(group_name)
    role_id = meadow_dn("Editors")

    with {:ok, connection} <- Exldap.connect() do
      LdapHelpers.add_entry(
        connection,
        group_id,
        LdapHelpers.group_attributes(group_name)
      )
    end

    result =
      query_gql(
        variables: %{"roleId" => role_id, "groupId" => group_id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    assert get_in(query_data, [:data, "addGroupToRole", "message"]) == "OK"
  end
end
