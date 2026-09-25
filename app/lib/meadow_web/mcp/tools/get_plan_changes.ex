defmodule MeadowWeb.MCP.Tools.GetPlanChanges do
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
        status: "proposed"
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
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.Planner
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
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
      description: "Optional status filter: proposed, approved, rejected, completed, error"
    )

    field(:user, :string,
      description: "Optional user filter to get changes approved/rejected by a specific user"
    )
  end

  @impl true
  def execute(%{plan_id: plan_id} = request, frame) do
    Logger.debug("MCP Server getting PlanChanges for plan: #{plan_id}")

    case Planner.get_plan(plan_id) do
      nil ->
        {:error, MCPError.protocol(:invalid_params, %{error: "Plan not found", plan_id: plan_id}),
         frame}

      _plan ->
        changes =
          plan_id
          |> Planner.list_plan_changes(build_criteria(request))
          |> Repo.preload(:plan)
          |> Enum.map(&serialize_change/1)

        {:reply, Response.tool() |> Response.structured(%{changes: changes}), frame}
    end
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
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
      add: flatten_operation(change.add),
      delete: flatten_operation(change.delete),
      replace: flatten_operation(change.replace),
      status: change.status,
      user: change.user,
      notes: change.notes,
      completed_at: change.completed_at,
      error: change.error,
      inserted_at: change.inserted_at,
      updated_at: change.updated_at,
      plan: serialize_plan(change.plan)
    }
  end

  # Echo the plan operations to the agent with repeating free-text fields as bare
  # strings, so it never sees (or re-proposes) the internal ValueEntry ids and
  # doesn't mistake them for controlled terms.
  defp flatten_operation(op) when is_map(op) do
    Map.new(op, fn
      {key, value}
      when key in ["descriptive_metadata", :descriptive_metadata] and is_map(value) ->
        {key, WorkDescriptiveMetadata.flatten_value_entries_map(value)}

      pair ->
        pair
    end)
  end

  defp flatten_operation(op), do: op

  defp serialize_plan(plan) do
    %{
      id: plan.id,
      prompt: plan.prompt,
      query: plan.query,
      status: plan.status,
      user: plan.user,
      notes: plan.notes,
      completed_at: plan.completed_at,
      error: plan.error,
      inserted_at: plan.inserted_at,
      updated_at: plan.updated_at
    }
  end
end
