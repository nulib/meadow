defmodule MeadowWeb.MCP.Server do
  @moduledoc "MeadowWeb.MCP Server definition"

  alias MeadowWeb.MCP

  use Anubis.Server,
    name: "meadow-mcp-server",
    version: "0.1.0",
    capabilities: [:tools]

  component(MCP.GetPlanChanges)
  component(MCP.GraphQL)
  component(MCP.IDQuery)
  component(MCP.ProposePlan)
  component(MCP.UpdatePlanChange)
end
