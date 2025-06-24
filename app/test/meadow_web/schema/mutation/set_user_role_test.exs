defmodule MeadowWeb.Schema.Mutation.SetUserRoleTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.Accounts.User

  load_gql(MeadowWeb.Schema, "test/gql/SetUserRole.gql")

  describe "setUserRole mutation" do
    setup do
      user = user_fixture(:manager)
      {:ok, %{user: user}}
    end

    test "should let an Administrator set a User's role", %{user: user} do
      assert User.find(user.id).role == :manager

      {:ok, result} =
        query_gql(
          variables: %{"userId" => user.id, "userRole" => "ADMINISTRATOR"},
          context: %{current_user: %{username: "abc122", role: :administrator}}
        )

      assert %{data: %{"setUserRole" => %{"message" => message}}} = result
      assert message == "User role updated successfully for #{user.id} to administrator"
      assert User.find(user.id).role == :administrator
    end

    test "non-admins are not authorized to assign roles", %{user: user} do
      assert User.find(user.id).role == :manager

      {:ok, result} =
        query_gql(
          variables: %{"userId" => user.id, "userRole" => "ADMINISTRATOR"},
          context: %{current_user: %{username: "abc122", role: :manager}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end
  end
end
