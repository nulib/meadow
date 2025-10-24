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
          {:ok, updated_plan} ->
            {:ok, updated_plan}

          {:error, changeset} ->
            {:error, message: "Could not update plan status", details: changeset}
        end
    end
  end

  def plan_changes(_, %{plan_id: plan_id}, _) do
    {:ok, Planner.list_plan_changes(plan_id, has_changes: true)}
  end

  def plan_change(_, %{id: id}, _) do
    case Planner.get_plan_change(id) do
      nil -> {:error, "Plan change not found"}
      plan_change -> {:ok, plan_change}
    end
  end

  def update_plan_change_status(_, %{id: id, status: status} = args, %{
        context: %{current_user: user}
      }) do
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
          {:ok, updated_change} ->
            {:ok, updated_change}

          {:error, changeset} ->
            {:error, message: "Could not update plan change status", details: changeset}
        end
    end
  end

  def update_proposed_plan_change_statuses(_, %{plan_id: plan_id, status: status} = args, %{
        context: %{current_user: user}
      }) do
    with {:ok, plan} <- fetch_plan(plan_id),
         {:ok, updated_plan, change_count} <- change_plan_changes(plan, status, args, user) do
      maybe_update_plan_status(status, {:ok, updated_plan, change_count}, user)

      {:ok, Planner.list_plan_changes(plan_id, has_changes: true)}
    else
      {:error, _} = error -> error
    end
  end

  def apply_plan(_, %{id: id}, _) do
    case Planner.get_plan(id) do
      nil ->
        {:error, "Plan not found"}

      plan ->
        case Planner.apply_plan(plan) do
          {:ok, updated_plan} ->
            {:ok, updated_plan}

          {:error, reason} when is_binary(reason) ->
            {:error, reason}

          {:error, changeset} ->
            {:error, message: "Could not apply plan", details: changeset}
        end
    end
  end

  defp fetch_plan(plan_id) do
    case Planner.get_plan(plan_id) do
      nil -> {:error, "Plan not found"}
      plan -> {:ok, plan}
    end
  end

  defp change_plan_changes(plan, :approved, _args, user) do
    Planner.approve_proposed_plan_changes(plan, user.username)
  end

  defp change_plan_changes(plan, :rejected, args, _user) do
    Planner.reject_proposed_plan_changes(plan, Map.get(args, :notes))
  end

  defp change_plan_changes(_plan, _status, _args, _user) do
    {:error, "Invalid status transition"}
  end

  defp maybe_update_plan_status(:approved, {:ok, plan, _count}, user) do
    Planner.approve_plan(plan, user.username)
  end

  defp maybe_update_plan_status(_, _result, _user), do: :ok
end
