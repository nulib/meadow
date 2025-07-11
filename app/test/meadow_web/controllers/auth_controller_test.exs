defmodule MeadowWeb.AuthControllerTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  alias MeadowWeb.Plugs.SetCurrentUser

  test "GET /auth/nusso/callback redirects to the referring page" do
    conn =
      build_conn()
      |> Plug.Conn.put_req_header("referer", "/project/list")

    conn = get(conn, "/auth/nusso/callback")

    assert "/project/list" == redirected_to(conn, 302)
  end

  describe "/auth/logout" do
    setup do
      user = user_fixture(:administrator)

      conn =
        build_conn()
        |> auth_user(user)
        |> SetCurrentUser.call(nil)

      {:ok, %{conn: conn, user: user}}
    end

    test "GET /auth/logout", %{conn: conn, user: user} do
      assert conn
             |> Plug.Conn.fetch_session()
             |> Plug.Conn.get_session(:current_user)
             |> Map.get(:username) == user.username

      assert get(conn, "/auth/logout")
             |> Plug.Conn.fetch_session()
             |> Plug.Conn.get_session(:current_user)
             |> is_nil()
    end
  end
end
