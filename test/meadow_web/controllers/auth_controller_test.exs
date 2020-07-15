defmodule MeadowWeb.AuthControllerTest do
  use MeadowWeb.ConnCase, async: true

  alias MeadowWeb.Plugs.SetCurrentUser

  test "GET /auth/nusso redirects to SSO url with a callback url", %{conn: conn} do
    assert get(conn, "/auth/nusso")
           |> redirected_to(302)
           |> URI.parse()
           |> Map.get(:fragment)
           |> URI.decode_query()
           |> Map.get("goto") == "https://www.example.com/auth/nusso/callback"
  end

  test "GET /auth/nusso/callback redirects to the referring page" do
    conn =
      build_conn()
      |> Plug.Conn.put_req_header("referer", "/project/list")

    conn = get(conn, "/auth/nusso/callback")

    assert "/project/list" == redirected_to(conn, 302)
  end

  describe "/auth/logout" do
    setup do
      user = user_fixture("TestAdmins")
      {:ok, %{user: user}}
    end

    test "GET /auth/logout removes user from cache", %{user: user} do
      conn =
        build_conn()
        |> auth_user(user)
        |> SetCurrentUser.call(nil)

      Cachex.put!(Meadow.Cache.Users, user.username, user)

      get(conn, "/auth/logout")

      assert Cachex.get!(Meadow.Cache.Users, user.username) == nil
    end
  end
end
