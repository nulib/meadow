defmodule Meadow.MCP.Server do
  @moduledoc "Meadow MCP Server definition"

  use Anubis.Server,
    name: "meadow-mcp-server",
    version: "0.1.0",
    capabilities: [:tools]

  component(Meadow.MCP.GraphQL)
end
