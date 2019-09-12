defmodule MeadowWeb.Schema.Query.IngestJobTest do
  use MeadowWeb.ConnCase, async: true

  import Mox

  @query """
  query($id: String!) {
    ingest_job(id: $id) {
      name
    }
  }
  """

  test "ingest job query returns the ingest job with a given id" do
    ingest_job = ingest_job_fixture()
    variables = %{"id" => ingest_job.id}

    conn = build_conn() |> auth_user(user_fixture())

    conn = get conn, "/api/graphql", query: @query, variables: variables

    assert %{
             "data" => %{
               "ingest_job" => %{"name" => ingest_job.name}
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

  test "gets a presigned url for an ingest job" do
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
