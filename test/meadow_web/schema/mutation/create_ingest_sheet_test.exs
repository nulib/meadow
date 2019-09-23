defmodule MeadowWeb.Schema.Mutation.CreateIngestSheet do
  use MeadowWeb.ConnCase, async: true

  @query """
    mutation ($name: String!, $filename: String!, $projectId: ID!) {
      createIngestSheet(name: $name, filename: $filename, projectId: $projectId) {
        name
        filename
        project {
          id
        }
      }
    }
  """

  test "createIngestSheet mutation creates an ingest sheet for a project", _context do
    project = project_fixture()

    input = %{
      "name" => "This is the name",
      "filename" => "filename.csv",
      "projectId" => project.id
    }

    conn = build_conn() |> auth_user(user_fixture())

    conn =
      post conn, "/api/graphql",
        query: @query,
        variables: input

    assert %{
             "data" => %{
               "createIngestSheet" => %{
                 "name" => "This is the name",
                 "filename" => "filename.csv",
                 "project" => %{
                   "id" => project.id
                 }
               }
             }
           } == json_response(conn, 200)
  end
end
