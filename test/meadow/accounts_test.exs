defmodule Meadow.AccountsTest do
  use ExUnit.Case
  use Meadow.Constants

  import Assertions
  import Meadow.TestHelpers

  alias Meadow.Accounts

  describe "user login" do
    test "user doesn't exist" do
      assert Accounts.authorize_user_login("nonExistentUser") == {:error, "Unauthorized"}
    end

    test "user without access" do
      assert Accounts.authorize_user_login("aui9865") == {:error, "Unauthorized"}
    end

    test "user with access" do
      with {result, user} <- Accounts.authorize_user_login("aua6615") do
        assert result == :ok
        assert user.username == "aua6615"
      end
    end
  end

  test "list roles" do
    Accounts.list_roles()
    |> entry_names()
    |> assert_lists_equal([
      "Administrators",
      "Managers",
      "Editors",
      "Users"
    ])
  end

  describe "group membership" do
    test "role members" do
      assert_lists_equal(
        Accounts.role_members(meadow_dn("Administrators")) |> entry_names(),
        ["Technology"]
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Editors")) |> entry_names(),
        []
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Managers")) |> entry_names(),
        ["Curators"]
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Users")) |> entry_names(),
        ["Curators", "Technology"]
      )
    end

    test "group members" do
      assert_lists_equal(
        Accounts.group_members("CN=Curators,OU=Departments,DC=library,DC=northwestern,DC=edu")
        |> entry_names(),
        ["aut2418", "aum1701", "auf2249", "aua6615"]
      )
    end
  end
end
