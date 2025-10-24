defmodule MeadowWeb.MCP.UpdatePlanChange do
  @moduledoc """
  MCP tool for updating a PlanChange entry with proposed modifications.

  This tool is used by the AI agent to populate pending plan changes with actual
  proposed modifications (add/delete/replace operations) and transition them to
  the 'proposed' status.

  ## Example Usage

      # Update a pending change with proposed modifications
      %{
        id: "change-uuid",
        add: %{
          descriptive_metadata: %{
            date_created: ["1896-11-10"]
          }
        },
        status: "proposed"
      }

      # Update with multiple operations
      %{
        id: "change-uuid",
        add: %{descriptive_metadata: %{contributor: [%{term: "Adams, Ansel, 1902-1984"}]}},
        delete: %{descriptive_metadata: %{subject: [%{term: "Photograph"}]}},
        status: "proposed"
      }
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "update_plan_change",
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.Planner
  alias Meadow.Repo
  require Logger

  schema do
    field(:id, :string,
      description: "The UUID of the PlanChange to update",
      required: true
    )

    field(:add, :map, description: "Map of values to append to existing work data")

    field(:delete, :map, description: "Map of values to remove from existing work data")

    field(:replace, :map, description: "Map of values to fully replace in work data")

    field(:status, :string,
      description: "Status: pending, proposed, approved, rejected, completed, error"
    )

    field(:notes, :string, description: "Optional notes about this change")
  end

  def name, do: "update_plan_change"

  @impl true
  def execute(%{id: id} = request, frame) do
    Logger.debug("MCP Server updating PlanChange: #{id}")

    case fetch_plan_change(id) do
      {:ok, change} ->
        attrs = build_attrs(request)

        case Planner.update_plan_change(change, attrs) do
          {:ok, updated_change} ->
            updated_change = Repo.preload(updated_change, :plan)
            {:reply, Response.tool() |> Response.json(serialize_change(updated_change)), frame}

          {:error, reason} ->
            {:error, MCPError.execution(reason), frame}
        end

      {:error, reason} ->
        {:error, MCPError.execution(reason), frame}
    end
  end

  defp fetch_plan_change(id) do
    case Planner.get_plan_change(id) do
      nil -> {:error, "PlanChange with id #{id} not found"}
      change -> {:ok, change}
    end
  end

  defp build_attrs(request) do
    Map.take(request, [:add, :delete, :replace, :status, :notes])
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
      completed_at: change.completed_at,
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
      completed_at: plan.completed_at,
      error: plan.error,
      inserted_at: plan.inserted_at,
      updated_at: plan.updated_at
    }
  end
end
