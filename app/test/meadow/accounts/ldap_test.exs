defmodule Meadow.Accounts.LdapTest do
  use ExUnit.Case
  use Meadow.Constants

  alias Meadow.Accounts.Ldap

  import Assertions
  import Meadow.TestHelpers

  describe "create groups" do
    test "create group" do
      try do
        preexisting_groups =
          Ldap.list_groups() |> Enum.map(fn %Ldap.Entry{name: name} -> name end)

        Ldap.create_group("TestGroup")

        with result <- Ldap.list_groups() |> Enum.map(fn %Ldap.Entry{name: name} -> name end) do
          assert_lists_equal(result, ["TestGroup" | preexisting_groups])
        end
      after
        delete_entry(meadow_dn("TestGroup"))
      end
    end

    test "create group that already exists" do
      {result, entry} = Ldap.create_group("Users")
      assert result == :exists
      assert entry.name == "Users"
    end
  end

  describe "group membership" do
    test "add/remove user to/from group" do
      user_id = random_user(:noAccess)

      assert test_users_dn(user_id)
             |> Ldap.list_user_groups()
             |> entry_names() == []

      assert meadow_dn("Users")
             |> Ldap.add_member(test_users_dn(user_id)) ==
               :ok

      assert_lists_equal(
        test_users_dn(user_id)
        |> Ldap.list_user_groups()
        |> entry_names(),
        ["Users"]
      )

      assert meadow_dn("Users")
             |> Ldap.remove_member(test_users_dn(user_id)) ==
               :ok

      assert test_users_dn(user_id)
             |> Ldap.list_user_groups()
             |> entry_names() == []
    end

    test "add user to group user is already a member of" do
      user_id = random_user(:noAccess) |> test_users_dn()

      try do
        assert meadow_dn("Users")
               |> Ldap.add_member(user_id) ==
                 :ok

        assert meadow_dn("Users")
               |> Ldap.add_member(user_id) ==
                 :exists
      after
        meadow_dn("Users")
        |> Ldap.remove_member(user_id)
      end
    end

    test "group as member of group" do
      user_id = test_users_dn(random_user("TestManagers"))

      assert_lists_equal(
        meadow_dn("Managers")
        |> Ldap.list_group_members()
        |> entry_names(),
        ["TestManagers"]
      )

      assert_lists_equal(
        meadow_dn("Users")
        |> Ldap.list_group_members()
        |> entry_names(),
        ["TestAdmins", "TestManagers"]
      )

      assert_lists_equal(
        user_id
        |> Ldap.list_user_groups()
        |> entry_names(),
        ["Users", "Managers"]
      )
    end
  end

  describe "entry attributes" do
    test "user attributes" do
      with entry <-
             Ldap.Entry.new(
               Ldap.connection(),
               test_users_dn(random_user())
             ) do
        assert entry.type == "user"

        with attrs <- entry.attributes do
          assert_lists_equal([:displayName, :mail, :description], attrs |> Map.keys())
          assert attrs.displayName |> String.match?(~r"^Test User\d+$")
          assert attrs.mail |> String.match?(~r"^TestUser\d+@example.com$")
        end
      end
    end

    test "group attributes" do
      with entry <-
             Ldap.Entry.new(
               Ldap.connection(),
               meadow_dn("Users")
             ) do
        assert entry.type == "group"
      end
    end

    test "other object attributes" do
      with entry <-
             Ldap.Entry.new(Ldap.connection(), "CN=System,DC=library,DC=northwestern,DC=edu") do
        assert entry.type == "unknown"
      end
    end
  end

  test "entry for nonexistent dn" do
    bad_dn = "CN=blah,OU=nonexistent,DC=library,DC=northwestern,DC=edu"
    assert Ldap.Entry.new(Ldap.connection(), bad_dn) == %Ldap.Entry{id: bad_dn, name: nil}
  end
end
