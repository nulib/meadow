defmodule Meadow.Data.Schemas.AgentPlanTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.AgentPlan

  describe "agent_plans" do
    @valid_attrs %{
      query: " id:(73293ebf-288b-4d4f-8843-488391796fea OR 2a27f163-c7fd-437c-8d4d-c2dbce72c884)",
      changeset: %{
        "descriptive_metadata" => %{
          "title" => "Updated Title"
        }
      }
    }

    @invalid_attrs %{
      query: nil,
      changeset: nil
    }

    test "valid attributes" do
      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(@valid_attrs)
        |> Repo.insert()

      assert plan.query == @valid_attrs.query
      assert plan.changeset == @valid_attrs.changeset
      assert plan.status == :pending
      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(plan.id)
    end

    test "valid attributes with user" do
      attrs = Map.put(@valid_attrs, :user, "test_user")

      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(attrs)
        |> Repo.insert()

      assert plan.user == "test_user"
    end

    test "invalid attributes" do
      assert {:error, %Ecto.Changeset{}} =
               %AgentPlan{}
               |> AgentPlan.changeset(@invalid_attrs)
               |> Repo.insert()
    end

    test "requires query" do
      changeset =
        %AgentPlan{}
        |> AgentPlan.changeset(Map.delete(@valid_attrs, :query))

      refute changeset.valid?
      assert %{query: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires changeset" do
      changeset =
        %AgentPlan{}
        |> AgentPlan.changeset(Map.delete(@valid_attrs, :changeset))

      refute changeset.valid?
      assert %{changeset: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates status is valid" do
      changeset =
        %AgentPlan{}
        |> AgentPlan.changeset(Map.put(@valid_attrs, :status, "invalid"))

      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "validates changeset is a map" do
      changeset =
        %AgentPlan{}
        |> AgentPlan.changeset(Map.put(@valid_attrs, :changeset, "not a map"))

      refute changeset.valid?
    end

    test "accepts any user string" do
      attrs = Map.put(@valid_attrs, :user, "any_user_string")

      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(attrs)
        |> Repo.insert()

      assert plan.user == "any_user_string"
    end
  end

  describe "approve/2" do
    setup do
      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(@valid_attrs)
        |> Repo.insert()

      {:ok, %{plan: plan}}
    end

    test "transitions plan to approved status with user", %{plan: plan} do
      {:ok, updated_plan} =
        plan
        |> AgentPlan.approve("approving_user")
        |> Repo.update()

      assert updated_plan.status == :approved
      assert updated_plan.user == "approving_user"
    end

    test "approves without user", %{plan: plan} do
      {:ok, updated_plan} =
        plan
        |> AgentPlan.approve()
        |> Repo.update()

      assert updated_plan.status == :approved
      assert updated_plan.user == nil
    end
  end

  describe "reject/2" do
    setup do
      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(@valid_attrs)
        |> Repo.insert()

      {:ok, %{plan: plan}}
    end

    test "transitions plan to rejected status", %{plan: plan} do
      {:ok, updated_plan} =
        plan
        |> AgentPlan.reject("Not appropriate")
        |> Repo.update()

      assert updated_plan.status == :rejected
      assert updated_plan.notes == "Not appropriate"
    end

    test "rejects without notes", %{plan: plan} do
      {:ok, updated_plan} =
        plan
        |> AgentPlan.reject()
        |> Repo.update()

      assert updated_plan.status == :rejected
      assert updated_plan.notes == nil
    end
  end

  describe "mark_executed/1" do
    setup do
      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(@valid_attrs)
        |> Repo.insert()

      {:ok, %{plan: plan}}
    end

    test "transitions plan to executed status with timestamp", %{plan: plan} do
      {:ok, updated_plan} =
        plan
        |> AgentPlan.mark_executed()
        |> Repo.update()

      assert updated_plan.status == :executed
      assert updated_plan.executed_at != nil
    end
  end

  describe "mark_error/2" do
    setup do
      {:ok, plan} =
        %AgentPlan{}
        |> AgentPlan.changeset(@valid_attrs)
        |> Repo.insert()

      {:ok, %{plan: plan}}
    end

    test "transitions plan to error status with error message", %{plan: plan} do
      error_message = "Failed to apply changeset"

      {:ok, updated_plan} =
        plan
        |> AgentPlan.mark_error(error_message)
        |> Repo.update()

      assert updated_plan.status == :error
      assert updated_plan.error == error_message
    end
  end
end
