defmodule MeadowWeb.ExportControllerTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  alias Meadow.Data.Indexer

  @query ~s({"query":{"term":{"model.name.keyword": "Work"}}})

  describe "POST /api/export/:filename (failure)" do
    test "unauthorized request", %{conn: conn} do
      conn =
        conn
        |> post("/api/export/export.csv", %{query: @query})

      assert text_response(conn, 403) =~ "Unauthorized"
    end

    test "unknown output type", %{conn: conn} do
      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/export/export.xls", %{query: @query})

      assert text_response(conn, 404) =~ "Not Found"
    end
  end

  describe "POST /api/export/:filename (success)" do
    setup do
      0..5 |> Enum.each(fn _ -> work_fixture() end)
      Indexer.synchronize_index()
    end

    test "successful request", %{conn: conn} do
      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/export/export.csv", %{query: @query})

      assert Plug.Conn.get_resp_header(conn, "content-disposition")
             |> Enum.member?(~s(attachment; filename="export.csv"))

      assert conn.state == :chunked
      assert response_content_type(conn, :csv)
      assert response(conn, 200)
    end
  end
end
