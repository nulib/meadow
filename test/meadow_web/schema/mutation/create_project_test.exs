defmodule MeadowWeb.Schema.Mutation.CreateProjectTest do
  use MeadowWeb.ConnCase, async: true

  @query """
    mutation ($title: String!) {
      createProject(title: $title) {
        title
      }
    }
  """

  test "createProject mutation creates a project", _context do
    input = %{
      "title" => "This is the title"
    }

    conn = build_conn() |> auth_user(user_fixture())

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
