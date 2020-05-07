defmodule MeadowWeb.Schema.Query.FetchCodedTermLabelTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/FetchCodedTermLabel.gql")

  describe "FetchCodedTermLabel.gql" do
    test "Is a valid query" do
      result =
        query_gql(
          variables: %{id: "http://vocab.getty.edu/aat/300021797"},
          context: gql_context()
        )

      assert {:ok, query_data} = result
    end
  end
end
