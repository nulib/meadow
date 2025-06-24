defmodule MeadowWeb.Schema.Mutation.ReplaceFileSetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Meadow.S3Case
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/ReplaceFileSet.gql")

  @bucket @ingest_bucket
  @key "create_file_set_test/file.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}

  @tag s3: [@fixture]
  test "replaceFileSet mutation updates a FileSet's metadata", _context do
    file_set = file_set_fixture()

    {:ok, result} =
      query_gql(
        variables: %{
          "id" => file_set.id,
          "coreMetadata" => %{
            "original_filename" => "file.tif",
            "location" => "s3://#{@bucket}/#{@key}"
          }
        },
        context: gql_context()
      )

    assert result.data["replaceFileSet"]
    location = get_in(result, [:data, "replaceFileSet", "coreMetadata", "location"])
    assert location == "s3://#{@bucket}/#{@key}"
  end

  describe "authorization" do
    @tag s3: [@fixture]
    test "viewers are not authorized to replace file sets" do
      file_set = file_set_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => file_set.id,
            "coreMetadata" => %{
              "original_filename" => "file.tif",
              "location" => "s3://#{@bucket}/#{@key}"
            }
          },
          context: %{current_user: %{role: :user}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end
  end
end
