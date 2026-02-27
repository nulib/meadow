defmodule MeadowWeb.MCP.Tools.ProposePlan do
  @moduledoc """
  MCP tool for changing the status of a Plan to proposed.
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.Planner
  require Logger

  schema do
    field(:plan_id, :string,
      description: "The UUID of the Plan to update",
      required: true
    )
  end

  @impl true
  def execute(%{plan_id: plan_id}, frame) do
    Logger.debug("MCP Server proposing plan: #{plan_id}")

    case Planner.get_plan(plan_id) do
      nil ->
        {:error, MCPError.protocol(:invalid_params, %{error: "Plan not found", plan_id: plan_id}), frame}

      plan ->
        propose_plan(plan, frame)
    end
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
  end

  defp propose_plan(plan, frame) do
    case Planner.propose_plan(plan) do
      {:ok, updated_plan} ->
        {:reply, Response.tool() |> Response.json(%{plan: updated_plan}), frame}

      {:error, reason} ->
        {:error, MCPError.execution(reason), frame}
    end
  end
end
