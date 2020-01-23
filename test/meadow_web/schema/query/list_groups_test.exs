defmodule MeadowWeb.Schema.Query.ListGroupsTest do
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase
  use Meadow.LdapCase

  load_gql(MeadowWeb.Schema, "test/gql/ListGroups.gql")

  describe "list groups" do
    setup do
      Ldap.create_group("ABC123")
      Ldap.create_group("DEF456")
      :ok
    end

    test "should be a valid query" do
      result =
        query_gql(
          variables: %{},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      groups = get_in(query_data, [:data, "groups"])
      assert length(groups) == 2
    end
  end
end
