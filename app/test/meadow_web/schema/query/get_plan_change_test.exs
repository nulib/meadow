defmodule MeadowWeb.Schema.Query.GetPlanChangeTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetPlanChange.gql")

  test "should be a valid query" do
    plan_change = plan_change_fixture()

    result =
      query_gql(
        variables: %{"id" => plan_change.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    plan_change_status = get_in(query_data, [:data, "planChange", "status"])
    assert plan_change_status == "PENDING"
  end

  test "should return nil for a non-existent plan change" do
    result = query_gql(variables: %{"id" => Ecto.UUID.generate()}, context: gql_context())
    assert {:ok, %{data: %{"planChange" => nil}}} = result
  end
end
