defmodule MeadowWeb.Schema.Query.GetPlanTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetPlan.gql")

  test "should be a valid query" do
    plan = plan_fixture()

    result =
      query_gql(
        variables: %{"id" => plan.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    plan_status = get_in(query_data, [:data, "plan", "status"])
    assert plan_status == "PENDING"
  end

  test "should return nil for a non-existent plan" do
    result = query_gql(variables: %{"id" => Ecto.UUID.generate()}, context: gql_context())
    assert {:ok, %{data: %{"plan" => nil}}} = result
  end
end
