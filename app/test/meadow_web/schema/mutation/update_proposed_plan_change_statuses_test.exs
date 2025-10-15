defmodule MeadowWeb.Schema.Mutation.UpdateProposedPlanChangeStatusesTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdateProposedPlanChangeStatuses.gql")

  setup do
    plan = plan_fixture()

    plan_changes = [
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :approved}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :rejected}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :rejected}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed}),
      plan_change_fixture(%{plan: plan, replace: %{collection_id: 123}, status: :proposed})
    ]

    {:ok, plan: plan, plan_changes: plan_changes}
  end

  test "should approve remaining proposed changes in the plan", %{
    plan: plan,
    plan_changes: plan_changes
  } do
    result =
      query_gql(
        variables: %{"planId" => plan.id, "status" => "APPROVED"},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updateProposedPlanChangeStatuses"])
    assert length(response) == length(plan_changes)
    assert not Enum.any?(response, fn pc -> pc["status"] == "PROPOSED" end)
    assert Enum.count(response, fn pc -> pc["status"] == "APPROVED" end) == 8
  end

  test "should reject remaining proposed changes in the plan with notes", %{
    plan: plan,
    plan_changes: plan_changes
  } do
    result =
      query_gql(
        variables: %{
          "planId" => plan.id,
          "status" => "REJECTED",
          "notes" => "Incorrect translation"
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "updateProposedPlanChangeStatuses"])
    assert length(response) == length(plan_changes)
    assert not Enum.any?(response, fn pc -> pc["status"] == "PROPOSED" end)
    assert Enum.count(response, fn pc -> pc["status"] == "REJECTED" end) == 9
    assert Enum.count(response, fn pc -> pc["notes"] == "Incorrect translation" end) == 7
  end

  test "should return error for non-existent plan" do
    result =
      query_gql(
        variables: %{"planId" => Ecto.UUID.generate(), "status" => "APPROVED"},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    error = List.first(get_in(query_data, [:errors]))
    assert error.message == "Plan not found"
  end
end
