defmodule MeadowWeb.Schema.Query.RolesTest do
  use Meadow.Constants

  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetRoles.gql")

  describe "roles query" do
    test "should return Meadow roles" do
      result = query_gql(context: gql_context())

      expected_roles = ["Superuser", "Administrator", "Manager", "Editor", "User"]

      assert {:ok, %{data: %{"roles" => roles}}} = result
      assert Enum.sort(roles) == Enum.sort(expected_roles)
    end
  end
end
