defmodule MeadowWeb.Plugs.SetCurrentUserTest do
  use MeadowWeb.ConnCase
  alias MeadowWeb.Plugs.SetCurrentUser

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
end
