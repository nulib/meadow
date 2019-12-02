defmodule MeadowWeb.Schema.Query.SheetTest do
  use MeadowWeb.ConnCase, async: true

  import Mox

  @query """
  query($id: String!) {
    ingest_sheet(id: $id) {
      name
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
               "ingest_sheet" => %{"name" => ingest_sheet.name}
             }
           } == json_response(conn, 200)
  end

  @query """
  query {
    presignedUrl {
      url
    }
  }
  """

  test "gets a presigned url for an ingest sheet" do
    Meadow.ExAwsHttpMock
    |> stub(:request, fn _method, _url, _body, _headers, _opts ->
      {:ok, %{status_code: 200}}
    end)

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query)

    assert %{
             "data" => %{
               "presignedUrl" => %{
                 "url" => _
               }
             }
           } = json_response(response, 200)
  end
end
