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
        |> auth_user(user_fixture(:administrator))
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
        |> auth_user(user_fixture(:administrator))
        |> post("/api/export/export.csv", %{query: @query})

      assert Plug.Conn.get_resp_header(conn, "content-disposition")
             |> Enum.member?(~s(attachment; filename="export.csv"))

      assert conn.state == :chunked
      assert response_content_type(conn, :csv)
      assert response(conn, 200)
    end
  end

  describe "POST /api/export/:filename (ingest sheet export)" do
    setup do
      {:ok, project} = Meadow.Ingest.Projects.create_project(%{title: "Test Project"})

      {:ok, sheet} =
        Meadow.Ingest.Sheets.create_ingest_sheet(%{
          title: "Test Sheet",
          filename: "s3://test-bucket/ingest_sheets/test-uuid.csv",
          project_id: project.id
        })

      %{sheet: sheet}
    end

    test "exports ingest sheet successfully via S3 redirect", %{conn: conn, sheet: sheet} do
      conn =
        conn
        |> auth_user(user_fixture(:administrator))
        |> post("/api/export/ingest_sheet.csv", %{sheet_id: sheet.id})

      assert redirected_to(conn, 302) =~ "test-bucket"
      assert redirected_to(conn, 302) =~ "ingest_sheets/test-uuid.csv"
    end

    test "returns 404 for non-existent ingest sheet", %{conn: conn} do
      conn =
        conn
        |> auth_user(user_fixture(:administrator))
        |> post("/api/export/ingest_sheet.csv", %{sheet_id: Ecto.UUID.generate()})

      assert text_response(conn, 404) =~ "Ingest sheet not found"
    end

    test "unauthorized ingest sheet export request", %{conn: conn, sheet: sheet} do
      conn =
        conn
        |> post("/api/export/ingest_sheet.csv", %{sheet_id: sheet.id})

      assert text_response(conn, 403) =~ "Unauthorized"
    end
  end
end
