defmodule MeadowWeb.Schema.Query.UsersTest do
  use Meadow.Constants

  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetUsers.gql")

  describe "users query" do
    test "should return Meadow users with elevated privileges" do
      result = query_gql(context: gql_context())

      expected = %{
        "displayName" => "Test User03",
        "email" => "TestUser03@example.com",
        "role" => "MANAGER",
        "username" => "auf2249"
      }

      assert {:ok, %{data: %{"users" => users}}} = result
      assert Enum.member?(users, expected)
      assert length(users) == 9
    end
  end
end
