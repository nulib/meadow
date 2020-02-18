defmodule MeadowWeb.Schema.Mutation.CreateFileSetTest do
  use MeadowWeb.ConnCase, async: true
  use Meadow.S3Case

  @bucket "test-ingest"
  @key "create_file_set_test/file.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}

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

  @tag s3: [@fixture]
  test "createFileSet mutation creates a FileSet", _context do
    work = work_fixture()

    input = %{
      "accession_number" => "99999",
      "role" => "AM",
      "work_id" => work.id,
      "metadata" => %{
        "description" => "Something",
        "original_filename" => "file.tif",
        "location" => "s3://#{@bucket}/#{@key}"
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
