defmodule MeadowWeb.MCP.Server do
  @moduledoc "MeadowWeb.MCP Server definition"

  alias MeadowWeb.MCP.{Resources, Tools}

  use Anubis.Server,
    name: "meadow-mcp-server",
    version: "0.1.0",
    capabilities: [:resources, :tools]

  component(Resources.Schemas.Work)
  component(Resources.Schemas.FileSet)
  component(Resources.Schemas.Collection)
  component(Tools.AuthoritySearch)
  component(Tools.GetImage)
  component(Tools.GetWork)
  component(Tools.GetCodeList)
  component(Tools.GetPlanChanges)
  component(Tools.IDQuery)
  component(Tools.ProposePlan)
  component(Tools.SendStatusUpdate)
  component(Tools.UpdatePlanChange)
end
