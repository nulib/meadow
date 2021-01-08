defmodule MeadowWeb.Schema.Mutation.MetadataUpdateTest do
  use MeadowWeb.ConnCase, async: true
  use Meadow.CSVMetadataUpdateCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/MetadataUpdate.gql")

  describe "valid update" do
    @describetag source: "test/fixtures/csv/work_fixture_update.csv"

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
