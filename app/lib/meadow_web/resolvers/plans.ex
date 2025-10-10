defmodule MeadowWeb.Resolvers.Data.Plans do
  @moduledoc """
  Absinthe resolver for Plan related functionality
  """
  alias Meadow.Data.Planner

  def plan(_, %{id: id}, _) do
    case Planner.get_plan(id) do
      nil -> {:error, "Plan not found"}
      plan -> {:ok, plan}
    end
  end

  def update_plan_status(_, %{id: id, status: status} = args, %{context: %{current_user: user}}) do
    case Planner.get_plan(id) do
      nil ->
        {:error, "Plan not found"}

      plan ->
        result =
          case status do
            :approved -> Planner.approve_plan(plan, user.username)
            :rejected -> Planner.reject_plan(plan, Map.get(args, :notes))
            _ -> {:error, "Invalid status transition"}
          end

        case result do
          {:ok, updated_plan} -> {:ok, updated_plan}
          {:error, changeset} -> {:error, message: "Could not update plan status", details: changeset}
        end
    end
  end

  def plan_changes(_, %{plan_id: plan_id}, _) do
    {:ok, Planner.list_plan_changes(plan_id)}
  end

  def plan_change(_, %{id: id}, _) do
    case Planner.get_plan_change(id) do
      nil -> {:error, "Plan change not found"}
      plan_change -> {:ok, plan_change}
    end
  end

  def update_plan_change_status(_, %{id: id, status: status} = args, %{context: %{current_user: user}}) do
    case Planner.get_plan_change(id) do
      nil ->
        {:error, "Plan change not found"}

      plan_change ->
        result =
          case status do
            :approved -> Planner.approve_plan_change(plan_change, user.username)
            :rejected -> Planner.reject_plan_change(plan_change, Map.get(args, :notes))
            _ -> {:error, "Invalid status transition"}
          end

        case result do
          {:ok, updated_change} -> {:ok, updated_change}
          {:error, changeset} -> {:error, message: "Could not update plan change status", details: changeset}
        end
    end
  end
end
