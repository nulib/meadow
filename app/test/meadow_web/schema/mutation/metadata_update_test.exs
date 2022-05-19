defmodule MeadowWeb.Schema.Mutation.MetadataUpdateTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Meadow.CSVMetadataUpdateCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/MetadataUpdate.gql")

  describe "missing file" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "should return an error" do
      result =
        query_gql(
          variables: %{
            "filename" => "missing.csv",
            "source" => "s3://#{@upload_bucket}/missing.csv"
          },
          context: gql_context()
        )

      assert {:ok, query_data} = result

      with [error] <- get_in(query_data, [:data, :errors]) do
        assert error.message == "Could not create job"
        assert error.details == "s3://#{@upload_bucket}/missing.csv does not exist"
      end
    end
  end

  describe "valid update" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "should be a valid mutation", %{source_url: source_url} do
      result =
        query_gql(
          variables: %{"filename" => Path.basename(source_url), "source" => source_url},
          context: gql_context()
        )

      assert {:ok, query_data} = result
      assert get_in(query_data, [:data, "csvMetadataUpdate", "status"]) == "pending"
      assert get_in(query_data, [:data, "csvMetadataUpdate", "user"]) == "user1"
    end
  end
end
