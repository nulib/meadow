defmodule MeadowWeb.PageControllerTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "react-app"
  end
end
