defmodule Meadow.Data.PlannerTest do
  use Meadow.DataCase

  alias Meadow.Data.Planner
  alias Meadow.Data.Schemas.AgentPlan

  @valid_attrs %{
    query: " id:(73293ebf-288b-4d4f-8843-488391796fea OR 2a27f163-c7fd-437c-8d4d-c2dbce72c884)",
    changeset: %{
      "descriptive_metadata" => %{
        "title" => "Updated Title"
      }
    }
  }

  @invalid_attrs %{query: nil, changeset: nil}

  describe "list_plans/0" do
    test "returns all agent plans" do
      {:ok, _plan} = Planner.create_plan(@valid_attrs)
      assert length(Planner.list_plans()) == 1
    end

    test "returns empty list when no plans exist" do
      assert Planner.list_plans() == []
    end
  end

  describe "list_plans/1" do
    test "filters plans by status" do
      {:ok, pending_plan} = Planner.create_plan(@valid_attrs)
      {:ok, approved_plan} = Planner.create_plan(@valid_attrs)
      Planner.approve_plan(approved_plan)

      pending_plans = Planner.list_plans(status: :pending)
      assert length(pending_plans) == 1
      assert hd(pending_plans).id == pending_plan.id
    end

    test "limits results" do
      Planner.create_plan(@valid_attrs)
      Planner.create_plan(@valid_attrs)
      Planner.create_plan(@valid_attrs)

      plans = Planner.list_plans(limit: 2)
      assert length(plans) == 2
    end

    test "filters by user" do
      attrs_with_user = Map.put(@valid_attrs, :user, "test_user")
      {:ok, user_plan} = Planner.create_plan(attrs_with_user)
      {:ok, _other_plan} = Planner.create_plan(@valid_attrs)

      user_plans = Planner.list_plans(user: "test_user")
      assert length(user_plans) == 1
      assert hd(user_plans).id == user_plan.id
    end

    test "orders results" do
      {:ok, plan1} = Planner.create_plan(@valid_attrs)
      {:ok, plan2} = Planner.create_plan(@valid_attrs)

      plans_asc = Planner.list_plans(order: :asc)
      assert hd(plans_asc).id == plan1.id

      plans_desc = Planner.list_plans(order: :desc)
      assert hd(plans_desc).id == plan2.id
    end
  end

  describe "get_plan!/1" do
    test "returns the plan with given id" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      assert %AgentPlan{} = retrieved_plan = Planner.get_plan!(plan.id)
      assert retrieved_plan.id == plan.id
    end

    test "raises if plan doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Planner.get_plan!(Ecto.UUID.generate())
      end
    end

    test "retrieves user field" do
      attrs = Map.put(@valid_attrs, :user, "test_user")
      {:ok, plan} = Planner.create_plan(attrs)

      retrieved_plan = Planner.get_plan!(plan.id)
      assert retrieved_plan.user == "test_user"
    end
  end

  describe "get_plan/1" do
    test "returns the plan with given id" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      assert %AgentPlan{} = retrieved_plan = Planner.get_plan(plan.id)
      assert retrieved_plan.id == plan.id
    end

    test "returns nil if plan doesn't exist" do
      assert Planner.get_plan(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_pending_plans/0" do
    test "returns only pending plans" do
      {:ok, pending1} = Planner.create_plan(@valid_attrs)
      {:ok, pending2} = Planner.create_plan(@valid_attrs)
      {:ok, approved} = Planner.create_plan(@valid_attrs)
      Planner.approve_plan(approved)

      pending_plans = Planner.get_pending_plans()
      assert length(pending_plans) == 2

      pending_ids = Enum.map(pending_plans, & &1.id)
      assert pending1.id in pending_ids
      assert pending2.id in pending_ids
      refute approved.id in pending_ids
    end

    test "returns empty list when no pending plans" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      Planner.approve_plan(plan)

      assert Planner.get_pending_plans() == []
    end
  end

  describe "get_approved_plans/0" do
    test "returns only approved plans" do
      {:ok, pending} = Planner.create_plan(@valid_attrs)
      {:ok, approved1} = Planner.create_plan(@valid_attrs)
      {:ok, approved2} = Planner.create_plan(@valid_attrs)
      Planner.approve_plan(approved1)
      Planner.approve_plan(approved2)

      approved_plans = Planner.get_approved_plans()
      assert length(approved_plans) == 2

      approved_ids = Enum.map(approved_plans, & &1.id)
      assert approved1.id in approved_ids
      assert approved2.id in approved_ids
      refute pending.id in approved_ids
    end

    test "returns empty list when no approved plans" do
      Planner.create_plan(@valid_attrs)

      assert Planner.get_approved_plans() == []
    end
  end

  describe "create_plan/1" do
    test "with valid data creates a plan" do
      assert {:ok, %AgentPlan{} = plan} = Planner.create_plan(@valid_attrs)
      assert plan.query == @valid_attrs.query
      assert plan.changeset == @valid_attrs.changeset
      assert plan.status == :pending
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Planner.create_plan(@invalid_attrs)
    end

    test "with user creates plan with user field" do
      attrs = Map.put(@valid_attrs, :user, "test_user")
      assert {:ok, %AgentPlan{} = plan} = Planner.create_plan(attrs)
      assert plan.user == "test_user"
    end
  end

  describe "create_plan!/1" do
    test "with valid data creates a plan" do
      assert %AgentPlan{} = plan = Planner.create_plan!(@valid_attrs)
      assert plan.query == @valid_attrs.query
    end

    test "with invalid data raises error" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Planner.create_plan!(@invalid_attrs)
      end
    end
  end

  describe "update_plan/2" do
    test "with valid data updates the plan" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      update_attrs = %{notes: "Updated notes"}

      assert {:ok, %AgentPlan{} = updated_plan} = Planner.update_plan(plan, update_attrs)
      assert updated_plan.notes == "Updated notes"
    end

    test "with invalid data returns error changeset" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Planner.update_plan(plan, %{status: "invalid"})
    end
  end

  describe "approve_plan/2" do
    test "transitions plan to approved status" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)

      assert {:ok, %AgentPlan{} = approved_plan} = Planner.approve_plan(plan)
      assert approved_plan.status == :approved
    end

    test "associates user with approval" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)

      assert {:ok, %AgentPlan{} = approved_plan} = Planner.approve_plan(plan, "test_user")
      assert approved_plan.status == :approved
      assert approved_plan.user == "test_user"
    end
  end

  describe "reject_plan/2" do
    test "transitions plan to rejected status" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)

      assert {:ok, %AgentPlan{} = rejected_plan} = Planner.reject_plan(plan)
      assert rejected_plan.status == :rejected
    end

    test "adds notes to rejection" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)

      assert {:ok, %AgentPlan{} = rejected_plan} =
               Planner.reject_plan(plan, "Not appropriate")

      assert rejected_plan.status == :rejected
      assert rejected_plan.notes == "Not appropriate"
    end
  end

  describe "mark_plan_executed/1" do
    test "transitions plan to executed status with timestamp" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)

      assert {:ok, %AgentPlan{} = executed_plan} = Planner.mark_plan_executed(plan)
      assert executed_plan.status == :executed
      assert executed_plan.executed_at != nil
    end
  end

  describe "mark_plan_error/2" do
    test "transitions plan to error status with error message" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      error_message = "Failed to apply changeset"

      assert {:ok, %AgentPlan{} = error_plan} = Planner.mark_plan_error(plan, error_message)
      assert error_plan.status == :error
      assert error_plan.error == error_message
    end
  end

  describe "delete_plan/1" do
    test "deletes the plan" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)

      assert {:ok, %AgentPlan{}} = Planner.delete_plan(plan)
      assert_raise Ecto.NoResultsError, fn -> Planner.get_plan!(plan.id) end
    end
  end

  describe "change_plan/2" do
    test "returns a plan changeset" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      assert %Ecto.Changeset{} = Planner.change_plan(plan)
    end

    test "returns changeset with changes" do
      {:ok, plan} = Planner.create_plan(@valid_attrs)
      changeset = Planner.change_plan(plan, %{notes: "New notes"})

      assert changeset.changes.notes == "New notes"
    end
  end
end
