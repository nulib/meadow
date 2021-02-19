defmodule RequireHttpsProxyTest do
  use MeadowWeb.ConnCase, async: false

  alias MeadowWeb.Plugs.RequireHttpsProxy

  describe "RequireHttpsProxy" do
    test "redirects proxied HTTP to HTTPS" do
      conn =
        build_conn()
        |> Plug.Conn.put_req_header("x-forwarded-proto", "http")
        |> RequireHttpsProxy.call(%{})

      assert conn.status == 302
      assert [location | []] = Plug.Conn.get_resp_header(conn, "location")
      assert location |> String.starts_with?("https:")
    end

    test "passes through proxied HTTPS" do
      conn =
        build_conn()
        |> Plug.Conn.put_req_header("x-forwarded-proto", "https")
        |> RequireHttpsProxy.call(%{})

      assert conn.status |> is_nil()
    end

    test "passes through unproxied" do
      conn =
        build_conn()
        |> RequireHttpsProxy.call(%{})

      assert conn.status |> is_nil()
    end
  end
end
