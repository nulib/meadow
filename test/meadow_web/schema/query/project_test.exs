defmodule MeadowWeb.Schema.Query.ProjectTest do
  use MeadowWeb.ConnCase

  @query """
  query($id: String!) {
    project(id: $id) {
      title
    }
  }
  """

  test "project query returns the project with a given id" do
    project = project_fixture()
    variables = %{"id" => project.id}

    conn = build_conn() |> auth_user(user_fixture())
    conn = get conn, "/api/graphql", query: @query, variables: variables

    assert %{
             "data" => %{
               "project" => %{"title" => project.title}
             }
           } == json_response(conn, 200)
  end
end
