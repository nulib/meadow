defmodule MeadowWeb.Schema.Query.RolesTest do
  use Meadow.Constants

  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetRoles.gql")

  describe "roles query" do
    test "should return Meadow roles" do
      result =
        query_gql(
          variables: %{},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      roles = get_in(query_data, [:data, "roles"])

      assert Enum.sort(Enum.map(roles, fn role -> role["name"] end)) == Enum.sort(@role_priority)
    end
  end
end
