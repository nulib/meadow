defmodule Meadow.Accounts.LdapTest do
  use Meadow.Constants
  use Meadow.LdapCase

  alias Meadow.Accounts.Ldap

  import Assertions
  import Meadow.LdapCase

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
      Enum.each(@role_priority, fn group -> Ldap.create_group(group) end)
      ["testUser1", "testUser2", "testUser3"] |> Enum.each(&create_ldap_user/1)
      "testGroup1" |> create_ldap_group()
      :ok
    end

    test "add user to group" do
      assert library_dn("testUser1") |> Ldap.list_user_groups() == []
      assert meadow_dn("Users") |> Ldap.add_member(library_dn("testUser1")) == :ok

      assert_lists_equal(
        library_dn("testUser1") |> Ldap.list_user_groups() |> display_names(),
        ["Users Group"]
      )

      assert meadow_dn("Editors") |> Ldap.add_member(library_dn("testUser1")) == :ok

      assert_lists_equal(
        library_dn("testUser1") |> Ldap.list_user_groups() |> display_names(),
        ["Editors Group", "Users Group"]
      )
    end

    test "add user to group user is already a member of" do
      assert meadow_dn("Users") |> Ldap.add_member(library_dn("testUser1")) == :ok
      assert meadow_dn("Users") |> Ldap.add_member(library_dn("testUser1")) == :exists
    end

    test "remove user from group" do
      meadow_dn("Managers") |> Ldap.add_member(library_dn("testUser1"))
      meadow_dn("Managers") |> Ldap.add_member(library_dn("testUser2"))

      assert_lists_equal(
        meadow_dn("Managers") |> Ldap.list_group_members() |> display_names(),
        ["User testUser1", "User testUser2"]
      )

      meadow_dn("Managers") |> Ldap.remove_member(library_dn("testUser1"))

      assert_lists_equal(
        meadow_dn("Managers") |> Ldap.list_group_members() |> display_names(),
        ["User testUser2"]
      )
    end

    test "group as member of group" do
      library_dn("testGroup1") |> Ldap.add_member(library_dn("testUser2"))
      meadow_dn("Editors") |> Ldap.add_member(library_dn("testGroup1"))
      meadow_dn("Editors") |> Ldap.add_member(library_dn("testUser3"))

      assert_lists_equal(
        meadow_dn("Editors") |> Ldap.list_group_members() |> display_names(),
        ["Group testGroup1", "User testUser3"]
      )

      assert_lists_equal(
        library_dn("testUser2") |> Ldap.list_user_groups() |> display_names(),
        ["Editors Group"]
      )
    end
  end

  describe "entry attributes" do
    test "user attributes" do
      with entry <- Ldap.Entry.new(Ldap.connection(), create_ldap_user("testUserX")) do
        assert entry.class == "user"

        with attrs <- entry.attributes do
          assert_lists_equal([:displayName, :mail, :uid], attrs |> Map.keys())
          assert attrs.displayName == "User testUserX"
          assert attrs.mail == "testUserX@library.northwestern.edu"
        end
      end
    end

    test "group attributes" do
      with {:ok, group} <- Ldap.create_group("TestGroup") do
        assert group.class == "group"
      end
    end

    test "other object attributes" do
      with entry <-
             Ldap.Entry.new(Ldap.connection(), "CN=System,DC=library,DC=northwestern,DC=edu") do
        assert entry.class == "unknown"
      end
    end
  end

  test "entry for nonexistent dn" do
    bad_dn = "CN=blah,OU=nonexistent,DC=library,DC=northwestern,DC=edu"
    assert Ldap.Entry.new(Ldap.connection(), bad_dn) == %Ldap.Entry{id: bad_dn, name: nil}
  end
end
