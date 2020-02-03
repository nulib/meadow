defmodule Meadow.AccountsTest do
  use Meadow.Constants
  use Meadow.LdapCase

  import Assertions
  import Meadow.LdapCase
  import Meadow.LdapHelpers

  alias Meadow.Accounts

  describe "user login" do
    test "user doesn't exist" do
      assert Accounts.authorize_user_login("nonExistentUser") == {:error, "Unauthorized"}
    end

    test "user without access" do
      create_ldap_user("nonMeadowUser")
      assert Accounts.authorize_user_login("nonMeadowUser") == {:error, "Unauthorized"}
    end

    test "user with access", %{ldap: ldap} do
      add_membership(ldap, meadow_dn("Users"), create_ldap_user("meadowUser"))

      with {result, user} <- Accounts.authorize_user_login("meadowUser") do
        assert result == :ok
        assert user.username == "meadowUser"
      end
    end
  end

  test "list groups" do
    Accounts.list_roles()
    |> Enum.map(&display_names/1)
    |> assert_lists_equal([
      "Group Administrators",
      "Group Managers",
      "Group Editors",
      "Group Users"
    ])
  end

  describe "group membership" do
    setup %{ldap: ldap} do
      with all_users_dn <- create_ldap_group("AllUsers") do
        ["adminUser", "adminEditor", "editorUser", "userUser"]
        |> Enum.each(fn username ->
          add_membership(ldap, all_users_dn, create_ldap_user(username))
        end)
      end

      add_membership(ldap, meadow_dn("Administrators"), library_dn("adminUser"))
      add_membership(ldap, meadow_dn("Administrators"), library_dn("adminEditor"))
      add_membership(ldap, meadow_dn("Editors"), library_dn("adminEditor"))
      add_membership(ldap, meadow_dn("Editors"), library_dn("editorUser"))
    end

    test "role members" do
      assert_lists_equal(
        Accounts.role_members(meadow_dn("Administrators")) |> display_names(),
        ["User adminUser", "User adminEditor"]
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Editors")) |> display_names(),
        ["User adminEditor", "User editorUser"]
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Managers")) |> display_names(),
        []
      )

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Users")) |> display_names(),
        []
      )
    end

    test "nested group" do
      assert :ok == Accounts.add_group_to_role(library_dn("AllUsers"), meadow_dn("Users"))

      assert_lists_equal(
        Accounts.role_members(meadow_dn("Users")) |> display_names(),
        ["Group AllUsers"]
      )
    end

    test "group members" do
      assert_lists_equal(
        Accounts.group_members(library_dn("AllUsers")) |> display_names(),
        ["User adminUser", "User adminEditor", "User editorUser", "User userUser"]
      )
    end
  end
end
