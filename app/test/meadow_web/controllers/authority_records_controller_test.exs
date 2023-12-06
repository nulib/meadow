defmodule MeadowWeb.AuthorityRecordsControllerTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  alias Meadow.Repo
  alias NUL.AuthorityRecords
  alias NUL.Schemas.AuthorityRecord

  describe "POST /api/authority_records/:filename (failure)" do
    test "unauthorized request", %{conn: conn} do
      conn =
        conn
        |> post("/api/authority_records/nul_authority_records.csv")

      assert text_response(conn, 403) =~ "Unauthorized"
    end

    test "unknown output type", %{conn: conn} do
      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/authority_records/nul_authority_records.pdf")

      assert text_response(conn, 404) =~ "Not Found"
    end
  end

  def authority_record_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        label: attrs[:label] || Faker.Person.name(),
        hint: attrs[:hint] || Faker.Lorem.sentence(2)
      })

    {:ok, authority_record} =
      %AuthorityRecord{}
      |> AuthorityRecord.changeset(attrs)
      |> Repo.insert()

    authority_record
  end

  describe "POST /api/authority_records/:filename (success)" do
    setup do
      [
        authority_record_fixture(%{label: "Ver Steeg, Clarence L.", hint: "(The Legend)"}),
        authority_record_fixture(%{label: "Ver Steeg, Dorothy A."}),
        authority_record_fixture(%{label: "Netsch, Walter A."})
      ]

      :ok
    end

    test "successful request", %{conn: conn} do
      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/authority_records/nul_authority_records.csv")

      assert Plug.Conn.get_resp_header(conn, "content-disposition")
             |> Enum.member?(~s(attachment; filename="nul_authority_records.csv"))

      assert conn.state == :chunked
      assert response_content_type(conn, :csv)
      assert response(conn, 200)
    end
  end

  describe "POST /api/authority_records/bulk_create" do
    setup %{fixture: fixture} do
      upload = %Plug.Upload{
        content_type: "text/csv",
        filename: "authority_import.csv",
        path: fixture
      }

      {:ok, %{upload: upload}}
    end

    @tag fixture: "test/fixtures/authority_records/bad_authority_import.csv"
    test "bad data, no referer", %{conn: conn, upload: upload} do
      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/authority_records/bulk_create", %{records: upload})

      assert response(conn, 400)
    end

    @tag fixture: "test/fixtures/authority_records/bad_authority_import.csv"
    test "bad data, w/referer", %{conn: conn, upload: upload} do
      referer = "https://example.edu/dashboards/nul-local-authorities"

      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> put_req_header("referer", referer)
        |> post("/api/authority_records/bulk_create", %{records: upload})

      assert response(conn, 302)
      assert [^referer] = get_resp_header(conn, "location")
    end

    @tag fixture: "test/fixtures/authority_records/good_authority_import.csv"
    test "good data", %{conn: conn, upload: upload} do
      precount = Meadow.Repo.aggregate(AuthorityRecord, :count)

      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/authority_records/bulk_create", %{records: upload})

      assert Meadow.Repo.aggregate(AuthorityRecord, :count) == precount + 3
      assert conn.state == :chunked
      assert response_content_type(conn, :csv)
      assert response(conn, 200)
    end

    @tag fixture: "test/fixtures/authority_records/good_authority_import.csv"
    test "one duplicate entry", %{conn: conn, upload: upload} do
      AuthorityRecords.create_authority_record(%{
        label: "Second Imported Thing",
        hint: "preexisting entry"
      })

      precount = Meadow.Repo.aggregate(AuthorityRecord, :count)

      conn =
        conn
        |> auth_user(user_fixture("TestAdmins"))
        |> post("/api/authority_records/bulk_create", %{records: upload})

      assert Meadow.Repo.aggregate(AuthorityRecord, :count) == precount + 2
      assert conn.state == :chunked
      assert response_content_type(conn, :csv)
      assert response(conn, 200)
    end
  end
end
