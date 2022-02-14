defmodule MeadowWeb.Schema.Query.GetBatchByIdTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetBatchById.gql")

  test "should be a valid query" do
    batch = batch_fixture()

    result =
      query_gql(
        variables: %{"id" => batch.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    batch_status = get_in(query_data, [:data, "batch", "status"])
    assert batch_status == "QUEUED"
  end

  test "Should return nil for a non-existent batch" do
    result = query_gql(variables: %{"id" => Ecto.UUID.generate()})
    assert {:ok, %{data: %{"batch" => nil}}} = result
  end
end
