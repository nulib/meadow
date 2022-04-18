defmodule MeadowWeb.Schema.Mutation.IngestFileSetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Meadow.S3Case
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/IngestFileSet.gql")

  @bucket @ingest_bucket
  @key "create_file_set_test/file.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}

  @tag s3: [@fixture]
  test "ingestFileSet mutation creates a FileSet", _context do
    work = work_fixture()

    {:ok, result} =
      query_gql(
        variables: %{
          "accession_number" => "99999",
          "role" => %{"id" => "A", "scheme" => "FILE_SET_ROLE"},
          "work_id" => work.id,
          "coreMetadata" => %{
            "description" => "Something",
            "original_filename" => "file.tif",
            "location" => "s3://#{@bucket}/#{@key}"
          }
        },
        context: gql_context()
      )

    assert result.data["ingestFileSet"]
  end

  describe "authorization" do
    @tag s3: [@fixture]
    test "viewers are not authorized to ingest file sets" do
      work = work_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "accession_number" => "99999",
            "role" => %{"id" => "A", "scheme" => "FILE_SET_ROLE"},
            "work_id" => work.id,
            "coreMetadata" => %{
              "description" => "Something",
              "original_filename" => "file.tif",
              "location" => "s3://#{@bucket}/#{@key}"
            }
          },
          context: %{current_user: %{role: "User"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end
  end
end
