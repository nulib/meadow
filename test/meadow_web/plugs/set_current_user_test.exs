defmodule MeadowWeb.Plugs.SetCurrentUserTest do
  use Meadow.LdapCase
  use MeadowWeb.ConnCase

  alias Meadow.Accounts.Ldap
  alias MeadowWeb.Plugs.SetCurrentUser

  import Assertions

  describe "without a valid session" do
    test "SetCurrentUser plug adds no user to the Absinthe Context" do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(current_user: nil)
        |> SetCurrentUser.call(nil)

      assert %{} == conn.private.absinthe.context
    end
  end

  describe "with a valid session" do
    setup do
      user = user_fixture()
      create_ldap_user(user.username)
      {:ok, %{user: user}}
    end

    test "SetCurrentUser plug adds the current user to the Absinthe Context", %{user: user} do
      conn =
        build_conn()
        |> auth_user(user)
        |> SetCurrentUser.call(nil)

      assert %{username: user.username, email: user.email, display_name: user.display_name} ==
               conn.private.absinthe.context.current_user
    end

    test "SetCurrentUser plug adds the user's groups to the Absinthe Context", %{user: user} do
      ["Administrators", "Managers", "Editors", "Viewers", "Users"]
      |> Enum.each(fn group -> Ldap.create_group(group) end)

      with username <- user.username,
           expected_groups <- ["Managers", "Users"] do
        create_ldap_user(username)

        expected_groups
        |> Enum.each(fn group -> meadow_dn(group) |> Ldap.add_member(library_dn(username)) end)

        conn =
          build_conn()
          |> auth_user(user)
          |> SetCurrentUser.call(nil)

        assert %{username: user.username, email: user.email, display_name: user.display_name} ==
                 conn.private.absinthe.context.current_user

        assert_lists_equal(
          expected_groups,
          conn.private.absinthe.context.user_groups
        )
      end
    end
  end
end
