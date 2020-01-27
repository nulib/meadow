defmodule MeadowWeb.Schema.Mutation.CreateFileSetTest do
  use MeadowWeb.ConnCase

  import Mox

  @query """
    mutation (
      $accession_number: String!
      $role: FileSetRole!
      $metadata: FileSetMetadataInput!
      $work_id: ID!
      ) {
      createFileSet(
        accessionNumber: $accession_number
        role: $role
        metadata: $metadata
        workId: $work_id
        )
      {
        id
      }
    }
  """

  test "createWork mutation creates a FileSet", _context do
    work = work_fixture()

    Meadow.ExAwsHttpMock
    |> stub(:request, fn _method, _url, _body, _headers, _opts ->
      {:ok, %{status_code: 200}}
    end)

    input = %{
      "accession_number" => "99999",
      "role" => "AM",
      "work_id" => work.id,
      "metadata" => %{
        "description" => "Something",
        "original_filename" => "file.tif",
        "location" => "s3://path/to/file/on/s3"
      }
    }

    conn = build_conn() |> auth_user(user_fixture())

    conn =
      post conn, "/api/graphql",
        query: @query,
        variables: input

    assert %{
             "data" => %{
               "createFileSet" => %{
                 "id" => _
               }
             }
           } = json_response(conn, 200)
  end
end
