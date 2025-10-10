defmodule MeadowWeb.Schema.Query.GetPlanChangesTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetPlanChanges.gql")

  test "should be a valid query" do
    plan = plan_fixture()
    plan_change = plan_change_fixture(%{plan: plan})

    result =
      query_gql(
        variables: %{"planId" => plan.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    changes = get_in(query_data, [:data, "planChanges"])
    assert is_list(changes)
    assert length(changes) == 1

    first_change = List.first(changes)
    assert first_change["id"] == plan_change.id
    assert first_change["status"] == "PENDING"
  end

  test "should return empty list for plan with no changes" do
    plan = plan_fixture()

    result =
      query_gql(
        variables: %{"planId" => plan.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    changes = get_in(query_data, [:data, "planChanges"])
    assert changes == []
  end
end
