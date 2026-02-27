defmodule MeadowWeb.Plugs.BearerAuthTest do
  use MeadowWeb.ConnCase, async: false

  alias Meadow.Utils.DCAPI
  alias MeadowWeb.Plugs.BearerAuth

  describe "BearerAuth Plug" do
    setup %{conn: conn, ttl: ttl, claims: claims} do
      conn =
        case ttl do
          nil ->
            conn
          ttl ->
            {:ok, %{token: token}} = DCAPI.token(ttl, claims)
            put_req_header(conn, "authorization", "Bearer #{token}")
        end
        |> Plug.Test.init_test_session(%{})
        |> BearerAuth.call([])

      {:ok, %{conn: conn}}
    end

    @tag ttl: 300, claims: [scopes: ["read:Public", "read:Published", "meadow:MCP"]]
    test "sets a session user when the token has meadow scopes", %{conn: conn} do
      assert conn |> fetch_session() |> get_session(:current_user)
    end

    @tag ttl: 300, claims: [scopes: ["read:Public", "read:Published"], is_superuser: true]
    test "sets a session user when the token is a superuser", %{conn: conn} do
      assert conn |> fetch_session() |> get_session(:current_user)
    end

    @tag ttl: 300, claims: [scopes: ["read:Public", "read:Published"]]
    test "does not set a session user when the token is not a superuser and does not have meadow scopes", %{conn: conn} do
      refute conn |> fetch_session() |> get_session(:current_user)
    end

    @tag ttl: -30, claims: [scopes: ["read:Public", "read:Published"], is_superuser: true]
    test "does not set a session user when the token is expired", %{conn: conn} do
      refute conn |> fetch_session() |> get_session(:current_user)
    end

    @tag ttl: nil, claims: nil
    test "does not set a session user when no Authorization header is present", %{conn: conn} do
      refute conn |> fetch_session() |> get_session(:current_user)
    end

    @tag ttl: nil, claims: nil
    test "does not set a session user when the token is invalid" do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_req_header("authorization", "Bearer INVALID_TOKEN")
        |> BearerAuth.call([])
      refute conn |> fetch_session() |> get_session(:current_user)
    end
  end
end
