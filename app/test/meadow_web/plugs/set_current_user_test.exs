defmodule MeadowWeb.Plugs.SetCurrentUserTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  alias Meadow.Accounts.User
  alias MeadowWeb.Plugs.SetCurrentUser

  describe "without a valid session" do
    test "SetCurrentUser plug adds no user to the Conn/Absinthe Context" do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(current_user: nil)
        |> SetCurrentUser.call(nil)

      assert %{auth_token: "", current_user: nil} == conn.private.absinthe.context
      assert nil == conn.assigns[:current_user]
    end
  end

  describe "with a valid session" do
    setup do
      user = user_fixture(:administrator)
      {:ok, %{user: user}}
    end

    test "SetCurrentUser plug adds the current user to the Conn/Absinthe Context", %{user: user} do
      conn =
        build_conn()
        |> auth_user(user)
        |> SetCurrentUser.call(nil)

      assert %User{
               username: user.username,
               email: user.email,
               id: user.id,
               display_name: user.display_name,
               role: :administrator
             } ==
               conn.private.absinthe.context.current_user

      assert %User{
               username: user.username,
               email: user.email,
               id: user.id,
               display_name: user.display_name,
               role: :administrator
             } ==
               conn.assigns[:current_user]
    end
  end
end
