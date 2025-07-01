defmodule RequireLoginTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  alias MeadowWeb.Plugs.RequireLogin

  test "RequireLogin Plug returns 401 status when user is not logged in" do
    conn =
      build_conn()
      |> RequireLogin.call(%{})

    assert conn.status == 401
  end

  test "RequireLogin Plug passes through when current_user is assigned" do
    user = user_fixture()

    conn =
      build_conn()
      |> assign(:current_user, user)
      |> RequireLogin.call(%{})

    assert conn.status == nil
  end
end
