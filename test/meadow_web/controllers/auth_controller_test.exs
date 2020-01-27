defmodule MeadowWeb.AuthControllerTest do
  use MeadowWeb.ConnCase, async: true

  test "GET /auth/openam redirects to SSO url with a callback url", %{conn: conn} do
    conn = get(conn, "/auth/openam")

    redirect_url =
      "https://websso.it.northwestern.edu/amserver/UI/Login?goto=http://www.example.com/auth/openam/callback"

    assert redirect_url == redirected_to(conn, 302)
  end

  test "GET /auth/openam/callback redirects to the referring page" do
    conn =
      build_conn()
      |> Plug.Conn.put_req_header("referer", "/project/list")

    conn = get(conn, "/auth/openam/callback")

    assert "/project/list" == redirected_to(conn, 302)
  end
end
