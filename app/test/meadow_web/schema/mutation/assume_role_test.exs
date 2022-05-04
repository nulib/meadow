defmodule MeadowWeb.Schema.Mutation.AssumeRoleTest do
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/AssumeRole.gql")

  describe "assumeRole mutation" do
    setup do
      user = user_fixture("TestAdmins")
      on_exit(fn -> Cachex.clear!(Meadow.Cache.Users) end)
      {:ok, %{user: user}}
    end

    test "should let an Administrator assume a User role", %{user: user} do
      Cachex.put!(Meadow.Cache.Users, user.username, user)

      result =
        query_gql(
          variables: %{"userRole" => "USER"},
          context: %{current_user: user}
        )

      assert {:ok, query_data} = result

      message = get_in(query_data, [:data, "assumeRole", "message"])
      assert message == "Role changed to: User"
    end

    test "non-admins are not authorized to assume roles" do
      {:ok, result} =
        query_gql(
          variables: %{"userRole" => "ADMINISTRATOR"},
          context: %{current_user: %{username: "abc122", role: "Manager"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end
  end
end
