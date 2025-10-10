defmodule MeadowWeb.Schema.Mutation.UpdatePlanStatusTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdatePlanStatus.gql")

  test "should approve a plan" do
    plan = plan_fixture()

    result =
      query_gql(
        variables: %{"id" => plan.id, "status" => "APPROVED"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanStatus", "status"])
    assert response == "APPROVED"

    user = get_in(query_data, [:data, "updatePlanStatus", "user"])
    assert user != nil
  end

  test "should reject a plan with notes" do
    plan = plan_fixture()

    result =
      query_gql(
        variables: %{"id" => plan.id, "status" => "REJECTED", "notes" => "Not needed"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanStatus", "status"])
    assert response == "REJECTED"

    notes = get_in(query_data, [:data, "updatePlanStatus", "notes"])
    assert notes == "Not needed"
  end

  test "should return error for non-existent plan" do
    result =
      query_gql(
        variables: %{"id" => Ecto.UUID.generate(), "status" => "APPROVED"},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    error = List.first(get_in(query_data, [:errors]))
    assert error.message == "Plan not found"
  end
end
