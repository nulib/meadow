defmodule MeadowWeb.Schema.Query.SheetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  @query """
  query($id: ID!) {
    ingest_sheet(id: $id) {
      title
    }
  }
  """

  test "ingest sheet query returns the ingest sheet with a given id" do
    ingest_sheet = ingest_sheet_fixture()
    variables = %{"id" => ingest_sheet.id}

    conn = build_conn() |> auth_user(user_fixture())

    conn = get conn, "/api/graphql", query: @query, variables: variables

    assert %{
             "data" => %{
               "ingest_sheet" => %{"title" => ingest_sheet.title}
             }
           } == json_response(conn, 200)
  end

  @query """
  query($uploadType: S3UploadType!) {
    presignedUrl(uploadType: $uploadType) {
      url
    }
  }
  """

  test "gets a presigned url for an ingest sheet" do
    conn = build_conn() |> auth_user(user_fixture())

    response =
      get(conn, "/api/graphql",
        query: @query,
        variables: %{
          "uploadType" => "INGEST_SHEET"
        }
      )

    assert %{
             "data" => %{
               "presignedUrl" => %{
                 "url" => _
               }
             }
           } = json_response(response, 200)
  end
end
