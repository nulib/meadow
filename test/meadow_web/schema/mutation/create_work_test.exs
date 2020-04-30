defmodule MeadowWeb.Schema.Mutation.CreateWorkTest do
  use MeadowWeb.ConnCase, async: true

  @query """
    mutation (
      $accession_number: String!
      $work_type: WorkType!
      $visibility: Visibility!
      $administrative_metadata: WorkAdministrativeMetadataInput!
      $descriptive_metadata: WorkDescriptiveMetadataInput!
      ) {
      createWork(
        accessionNumber: $accession_number
        workType: $work_type
        visibility: $visibility
        administrativeMetadata: $administrative_metadata
        descriptiveMetadata: $descriptive_metadata
        )
      {
        id
      }
    }
  """

  test "createWork mutation creates a work", _context do
    input = %{
      "accession_number" => "99999",
      "visibility" => "OPEN",
      "work_type" => "IMAGE",
      "descriptive_metadata" => %{"title" => ["Something"]},
      "administrative_metadata" => %{"preservation_level" => 1}
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
