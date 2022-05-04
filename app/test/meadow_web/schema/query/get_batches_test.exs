defmodule MeadowWeb.Schema.Query.BatchesTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetBatches.gql")

  test "should be a valid query" do
    batch_fixture()
    batch_fixture()
    batch_fixture()

    result =
      query_gql(
        variables: %{},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    batches = get_in(query_data, [:data, "batches"])
    assert length(batches) == 3
  end
end
