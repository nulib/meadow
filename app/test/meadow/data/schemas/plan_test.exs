defmodule Meadow.Data.Schemas.PlanTest do
  use Meadow.DataCase
  alias Meadow.Data.Schemas.Plan

  @valid_attrs %{
    prompt: "Translate titles to Spanish in alternate_title field",
    query: "collection.id:abc-123"
  }

  @invalid_attrs %{prompt: nil}

  describe "changeset/2" do
    test "with valid attributes" do
      changeset = Plan.changeset(%Plan{}, @valid_attrs)
      assert changeset.valid?
    end

    test "without required prompt" do
      changeset = Plan.changeset(%Plan{}, @invalid_attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).prompt
    end

    test "validates status is in allowed values" do
      changeset = Plan.changeset(%Plan{}, Map.put(@valid_attrs, :status, :invalid_status))
      refute changeset.valid?
    end

    test "allows valid status values" do
      for status <- [:pending, :proposed, :approved, :rejected, :completed, :error] do
        changeset = Plan.changeset(%Plan{}, Map.put(@valid_attrs, :status, status))
        assert changeset.valid?
      end
    end

    test "query is optional" do
      changeset = Plan.changeset(%Plan{}, Map.delete(@valid_attrs, :query))
      assert changeset.valid?
    end
  end

  describe "approve/2" do
    test "transitions to approved status" do
      plan = %Plan{status: :proposed}
      changeset = Plan.approve(plan, "user@example.com")

      assert changeset.valid?
      assert get_change(changeset, :status) == :approved
      assert get_change(changeset, :user) == "user@example.com"
    end

    test "works without user" do
      plan = %Plan{status: :proposed}
      changeset = Plan.approve(plan)

      assert changeset.valid?
      assert get_change(changeset, :status) == :approved
    end
  end

  describe "reject/2" do
    test "transitions to rejected status with notes" do
      plan = %Plan{status: :proposed}
      changeset = Plan.reject(plan, "Changes not needed")

      assert changeset.valid?
      assert get_change(changeset, :status) == :rejected
      assert get_change(changeset, :notes) == "Changes not needed"
    end

    test "works without notes" do
      plan = %Plan{status: :proposed}
      changeset = Plan.reject(plan)

      assert changeset.valid?
      assert get_change(changeset, :status) == :rejected
    end
  end

  describe "mark_completed/1" do
    test "transitions to completed status with timestamp" do
      plan = %Plan{status: :approved}
      changeset = Plan.mark_completed(plan)

      assert changeset.valid?
      assert get_change(changeset, :status) == :completed
      assert get_change(changeset, :completed_at)
    end
  end

  describe "mark_error/2" do
    test "transitions to error status with error message" do
      plan = %Plan{status: :approved}
      changeset = Plan.mark_error(plan, "Database connection failed")

      assert changeset.valid?
      assert get_change(changeset, :status) == :error
      assert get_change(changeset, :error) == "Database connection failed"
    end
  end

  describe "integration scenarios" do
    test "Spanish translation workflow" do
      # Agent creates plan with prompt and query
      {:ok, plan} =
        %Plan{}
        |> Plan.changeset(%{
          prompt: "Translate titles to Spanish in alternate_title field",
          query: "collection.id:abc-123",
          status: :proposed
        })
        |> Repo.insert()

      assert plan.status == :proposed
      assert plan.prompt == "Translate titles to Spanish in alternate_title field"

      # User approves the plan
      {:ok, approved_plan} =
        plan
        |> Plan.approve("user@example.com")
        |> Repo.update()

      assert approved_plan.status == :approved
      assert approved_plan.user == "user@example.com"

      # System marks as completed
      {:ok, completed_plan} =
        approved_plan
        |> Plan.mark_completed()
        |> Repo.update()

      assert completed_plan.status == :completed
      assert completed_plan.completed_at
    end

    test "LCNAF lookup workflow with error" do
      # Agent creates plan
      {:ok, plan} =
        %Plan{}
        |> Plan.changeset(%{
          prompt: "Look up LCNAF names from description and assign as contributors",
          query: "id:(work-1 OR work-2)"
        })
        |> Repo.insert()

      # User approves
      {:ok, approved_plan} =
        plan
        |> Plan.approve("admin@example.com")
        |> Repo.update()

      # Execution encounters error
      {:ok, error_plan} =
        approved_plan
        |> Plan.mark_error("LOC API unavailable")
        |> Repo.update()

      assert error_plan.status == :error
      assert error_plan.error == "LOC API unavailable"
    end

    test "rejection workflow" do
      # Agent creates plan
      {:ok, plan} =
        %Plan{}
        |> Plan.changeset(%{
          prompt: "Delete all works in collection",
          query: "collection.id:xyz"
        })
        |> Repo.insert()

      # User rejects with notes
      {:ok, rejected_plan} =
        plan
        |> Plan.reject("This would delete important works")
        |> Repo.update()

      assert rejected_plan.status == :rejected
      assert rejected_plan.notes == "This would delete important works"
    end
  end
end
