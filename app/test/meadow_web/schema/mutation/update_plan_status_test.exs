defmodule MeadowWeb.Schema.Mutation.UpdatePlanStatusTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.AI.Provenance
  alias Meadow.Data.Planner

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

    user = get_in(query_data, [:data, "updatePlanStatus", "user"])
    assert user != nil
  end

  test "rejecting a plan cascades to its changes and records provenance" do
    plan = plan_fixture()
    work = work_fixture()

    {:ok, activity} =
      Provenance.create_activity(%{
        activity_type: "metadata_plan",
        work_id: work.id,
        plan_id: plan.id,
        status: "completed"
      })

    Provenance.record_targets_for_operations(
      activity,
      "Work",
      work.id,
      %{add: %{descriptive_metadata: %{description: ["AI proposal"]}}},
      origin: "ai_generated",
      status: "proposed",
      event_type: "proposed"
    )

    {:ok, change} =
      Planner.create_plan_change(%{
        plan_id: plan.id,
        work_id: work.id,
        add: %{descriptive_metadata: %{description: ["AI proposal"]}},
        status: :proposed,
        ai_activity_id: activity.id
      })

    result =
      query_gql(
        variables: %{"id" => plan.id, "status" => "REJECTED", "notes" => "Not needed"},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    assert get_in(query_data, [:data, "updatePlanStatus", "status"]) == "REJECTED"

    change = Planner.get_plan_change!(change.id)
    assert change.status == :rejected
    assert change.user != nil

    [target] = Provenance.get_activity!(activity.id).targets
    assert target.status == "rejected"
    assert Enum.any?(target.events, &(&1.event_type == "rejected"))
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
