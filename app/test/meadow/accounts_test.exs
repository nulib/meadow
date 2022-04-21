defmodule Meadow.AccountsTest do
  use ExUnit.Case
  use Meadow.Constants

  import Assertions
  import Meadow.TestHelpers

  alias Meadow.Accounts

  describe "user login" do
    test "user doesn't exist" do
      assert Accounts.authorize_user_login(random_user(:unknown)) == {:error, "Unauthorized"}
    end

    test "user without access" do
      assert Accounts.authorize_user_login(random_user(:noAccess)) == {:error, "Unauthorized"}
    end

    test "user with access" do
      username = random_user(:access)

      with {result, user} <- Accounts.authorize_user_login(username) do
        assert result == :ok
        assert user.username == username
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
        ["TestAdmins"]
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Editors")) |> entry_names(),
        []
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Managers")) |> entry_names(),
        ["TestManagers"]
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Users")) |> entry_names(),
        ["TestAdmins", "TestManagers"]
      )
    end

    test "group members" do
      assert_lists_equal(
        Accounts.group_members("CN=TestAdmins,OU=Departments,DC=library,DC=northwestern,DC=edu")
        |> entry_names(),
        test_users("TestAdmins")
      )
    end
  end
end
