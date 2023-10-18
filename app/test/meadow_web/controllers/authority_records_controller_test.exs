defmodule MeadowWeb.AuthorityRecordsControllerTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

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
end
