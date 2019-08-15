defmodule MeadowWeb.Schema.Mutation.CreateProjectTest do
  use MeadowWeb.ConnCase, async: true

  import Mox

  @query """
    mutation ($title: String!) {
      createProject(title: $title) {
        title
      }
    }
  """

  test "createProject mutation creates a project", _context do
    Meadow.ExAwsHttpMock
    |> stub(:request, fn _method, _url, _body, _headers, _opts ->
      {:ok, %{status_code: 200}}
    end)

    input = %{
      "title" => "This is the title"
    }

    conn = build_conn()

    conn =
      post conn, "/api/graphql",
        query: @query,
        variables: input

    assert %{
             "data" => %{
               "createProject" => %{
                 "title" => "This is the title"
               }
             }
           } == json_response(conn, 200)
  end
end
