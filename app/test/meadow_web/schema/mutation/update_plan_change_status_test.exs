defmodule MeadowWeb.Schema.Mutation.UpdatePlanChangeStatusTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdatePlanChangeStatus.gql")

  test "should approve a plan change" do
    plan_change = plan_change_fixture()

    result =
      query_gql(
        variables: %{"id" => plan_change.id, "status" => "APPROVED"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanChangeStatus", "status"])
    assert response == "APPROVED"

    user = get_in(query_data, [:data, "updatePlanChangeStatus", "user"])
    assert user != nil
  end

  test "should reject a plan change with notes" do
    plan_change = plan_change_fixture()

    result =
      query_gql(
        variables: %{"id" => plan_change.id, "status" => "REJECTED", "notes" => "Incorrect translation"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updatePlanChangeStatus", "status"])
    assert response == "REJECTED"

    notes = get_in(query_data, [:data, "updatePlanChangeStatus", "notes"])
    assert notes == "Incorrect translation"
  end

  test "should return error for non-existent plan change" do
    result =
      query_gql(
        variables: %{"id" => Ecto.UUID.generate(), "status" => "APPROVED"},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    error = List.first(get_in(query_data, [:errors]))
    assert error.message == "Plan change not found"
  end
end
