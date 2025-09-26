defmodule MeadowWeb.Schema.Mutation.AssumeRoleTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/AssumeRole.gql")

  describe "assumeRole mutation" do
    setup do
      user = user_fixture(:administrator)
      {:ok, %{user: user}}
    end

    test "should let an Administrator assume a User role", %{user: user} do
      result =
        query_gql(
          variables: %{"userRole" => "USER"},
          context: %{current_user: user}
        )

      assert {:ok, query_data} = result

      message = get_in(query_data, [:data, "assumeRole", "message"])
      assert message == "Role changed to: user"
    end

    test "non-admins are not authorized to assume roles" do
      {:ok, result} =
        query_gql(
          variables: %{"userRole" => "ADMINISTRATOR"},
          context: gql_context(%{role: :manager})
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end
  end
end
