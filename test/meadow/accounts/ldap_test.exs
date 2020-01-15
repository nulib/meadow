defmodule Meadow.Accounts.LdapTest do
  use Meadow.LdapCase
  import Assertions

  @groups ["Administrators", "Managers", "Editors", "Viewers", "Users"]

  describe "create groups" do
    test "create group" do
      assert Ldap.list_groups() == []
      Ldap.create_group("TestGroup")

      with result <- Ldap.list_groups() |> Enum.map(fn %Ldap.Entry{name: name} -> name end) do
        assert_lists_equal(result, ["TestGroup"])
      end
    end

    test "create group that already exists" do
      {result, entry} = Ldap.create_group("TestGroup")
      assert result == :ok
      assert entry.name == "TestGroup"

      {result, entry} = Ldap.create_group("TestGroup")
      assert result == :exists
      assert entry.name == "TestGroup"
    end
  end

  describe "group membership" do
    setup do
      Enum.each(@groups, fn group -> Ldap.create_group(group) end)
      create_users(["testUser1", "testUser2", "testUser3"])
      :ok
    end

    test "add user to group" do
      assert Ldap.list_user_groups("testUser1") == []
      assert Ldap.add_user("testUser1", "Users") == :ok
      assert_lists_equal(Ldap.list_user_groups("testUser1") |> Ldap.display_names(), ["Users"])
      assert Ldap.add_user("testUser1", "Editors") == :ok

      assert_lists_equal(Ldap.list_user_groups("testUser1") |> Ldap.display_names(), [
        "Editors",
        "Users"
      ])
    end

    test "add user to group user is already a member of" do
      assert Ldap.add_user("testUser1", "Users") == :ok
      assert Ldap.add_user("testUser1", "Users") == :exists
    end

    test "remove user from group" do
      Ldap.add_user("testUser1", "Managers")
      Ldap.add_user("testUser2", "Managers")

      assert_lists_equal(Ldap.list_group_members("Managers") |> Ldap.display_names(), [
        "testUser1",
        "testUser2"
      ])

      Ldap.remove_user("testUser1", "Managers")

      assert_lists_equal(Ldap.list_group_members("Managers") |> Ldap.display_names(), [
        "testUser2"
      ])
    end
  end

  describe "fetch distinguished names for users" do
    setup do
      {:ok, conn: Ldap.connection(), dn: create_user("testUser1")}
    end

    test "from User model", %{dn: expected} do
      assert Ldap.user_dn(%Meadow.Accounts.Schemas.User{username: "testUser1"}) == expected
    end

    test "from user's Ldap.Entry", %{conn: conn, dn: expected} do
      assert Ldap.user_dn(Ldap.Entry.new(conn, expected)) == expected
    end

    test "from a username", %{dn: expected} do
      assert Ldap.user_dn("testUser1") == expected
    end
  end

  test "entry for nonexistent dn" do
    bad_dn = "CN=blah,OU=nonexistent,DC=library,DC=northwestern,DC=edu"
    assert Ldap.Entry.new(Ldap.connection(), bad_dn) == %Ldap.Entry{id: bad_dn, name: nil}
  end
end
