defmodule MeadowWeb.MCP.GetPlanChanges do
  @moduledoc """
  MCP tool for retrieving PlanChange entries from the database.

  ## Example Usage

      # Get all changes for a plan
      %{
        plan_id: "plan-uuid"
      }

      # Get changes for a specific work within a plan
      %{
        plan_id: "plan-uuid",
        work_id: "work-uuid"
      }

      # Filter by status
      %{
        plan_id: "plan-uuid",
        status: "pending"
      }

      # Combine filters
      %{
        plan_id: "plan-uuid",
        work_id: "work-uuid",
        status: "approved"
      }
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "get_plan_changes",
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.Planner
  alias Meadow.Repo
  require Logger

  schema do
    field(:plan_id, :string,
      description: "The UUID of the Plan to retrieve changes for",
      required: true
    )

    field(:work_id, :string,
      description: "Optional work UUID to filter changes for a specific work"
    )

    field(:status, :string,
      description: "Optional status filter: pending, approved, rejected, executed, error"
    )

    field(:user, :string,
      description: "Optional user filter to get changes approved/rejected by a specific user"
    )
  end

  @impl true
  def name, do: "get_plan_changes"

  @impl true
def execute(%{plan_id: plan_id} = request, frame) do
  Logger.debug("MCP Server getting PlanChanges for plan: #{plan_id}")

  case fetch_plan(plan_id) do
    {:ok, _plan} ->
      changes =
        plan_id
        |> Planner.list_plan_changes(build_criteria(request))
        |> Repo.preload(:plan)
        |> Enum.map(&serialize_change/1)

      {:reply, Response.tool() |> Response.json(%{changes: changes}), frame}

    {:error, reason} ->
      {:error, MCPError.execution(reason), frame}
  end
end

defp fetch_plan(plan_id) do
  case Planner.get_plan(plan_id) do
    nil -> {:error, "Plan with id #{plan_id} not found"}
    plan -> {:ok, plan}
  end
end

defp build_criteria(request) do
  for {k, v} <- Map.take(request, [:work_id, :status, :user]),
      not is_nil(v),
      do: {k, v}
end

defp serialize_change(change) do
  %{
    id: change.id,
    plan_id: change.plan_id,
    work_id: change.work_id,
    add: change.add,
    delete: change.delete,
    replace: change.replace,
    status: change.status,
    user: change.user,
    notes: change.notes,
    executed_at: change.executed_at,
    error: change.error,
    inserted_at: change.inserted_at,
    updated_at: change.updated_at,
    plan: serialize_plan(change.plan)
  }
end

defp serialize_plan(plan) do
  %{
    id: plan.id,
    prompt: plan.prompt,
    query: plan.query,
    status: plan.status,
    user: plan.user,
    notes: plan.notes,
    executed_at: plan.executed_at,
    error: plan.error,
    inserted_at: plan.inserted_at,
    updated_at: plan.updated_at
  }
end
end
