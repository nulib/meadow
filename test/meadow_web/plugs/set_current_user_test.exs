defmodule MeadowWeb.Plugs.SetCurrentUserTest do
  use Meadow.LdapCase
  use MeadowWeb.ConnCase

  alias Meadow.Accounts.Ldap
  alias MeadowWeb.Plugs.SetCurrentUser

  import Assertions

  test "with a valid session, SetCurrentUser plug adds the current user to the Absinthe Context" do
    user = user_fixture()

    conn =
      build_conn()
      |> auth_user(user)
      |> SetCurrentUser.call(nil)

    assert %{username: user.username, email: user.email, display_name: user.display_name} ==
             conn.private.absinthe.context.current_user
  end

  test "without a valid session, SetCurrentUser plug adds no user to the Absinthe Context" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(current_user: nil)
      |> SetCurrentUser.call(nil)

    assert %{} == conn.private.absinthe.context
  end

  describe "with LDAP groups" do
    setup do
      ["Administrators", "Managers", "Editors", "Viewers", "Users"]
      |> Enum.each(fn group -> Ldap.create_group(group) end)

      :ok
    end

    test "with a valid session, SetCurrentUser plug adds the current user's groups to the Absinthe Context" do
      with user <- user_fixture(),
           expected_groups <- ["Managers", "Users"] do
        create_ldap_user(user.username)
        expected_groups |> Enum.each(fn group -> user |> Ldap.add_user(group) end)

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
