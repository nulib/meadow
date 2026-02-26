defmodule MeadowWeb.Plugs.AuthorizeTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false

  alias MeadowWeb.Plugs.Authorize

  defmodule PassThroughPlug do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, opts) do
      send_resp(conn, 200, "Pass! (with #{inspect(opts)})")
    end
  end

  setup do
    {:ok, %{opts: [require: :editor, forward_to: {PassThroughPlug, [option: "value"]}]}}
  end

  test "Authorize Plug returns 401 status when user is not logged in", %{opts: opts} do
    conn =
      build_conn()
      |> Authorize.call(opts)

    assert conn.status == 401
  end

  test "Authorize Plug passes through when current_user is not authorized", %{opts: opts} do
    user = user_fixture(:user)

    conn =
      build_conn()
      |> assign(:current_user, user)
      |> Authorize.call(opts)

    assert conn.status == 401
  end

  test "Authorize Plug passes through when current_user is authorized", %{opts: opts} do
    user = user_fixture(:editor)

    conn =
      build_conn()
      |> assign(:current_user, user)
      |> Authorize.call(opts)

    assert conn.status == 200
    assert conn.resp_body == "Pass! (with [option: \"value\"])"
  end
end
