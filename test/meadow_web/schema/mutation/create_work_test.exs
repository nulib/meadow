defmodule MeadowWeb.Schema.Mutation.CreateWorkTest do
  use MeadowWeb.ConnCase

  import Mox

  @query """
    mutation (
      $accession_number: String!
      $work_type: WorkType!
      $visibility: Visibility!
      $metadata: WorkMetadataInput!
      ) {
      createWork(
        accessionNumber: $accession_number
        workType: $work_type
        visibility: $visibility
        metadata: $metadata
        )
      {
        id
      }
    }
  """

  test "createWork mutation creates a work", _context do
    Meadow.ExAwsHttpMock
    |> stub(:request, fn _method, _url, _body, _headers, _opts ->
      {:ok, %{status_code: 200}}
    end)

    input = %{
      "accession_number" => "99999",
      "visibility" => "OPEN",
      "work_type" => "IMAGE",
      "metadata" => %{"title" => "Something"}
    }

    conn = build_conn() |> auth_user(user_fixture())

    conn =
      post conn, "/api/graphql",
        query: @query,
        variables: input

    assert %{
             "data" => %{
               "createWork" => %{
                 "id" => _
               }
             }
           } = json_response(conn, 200)
  end
end
