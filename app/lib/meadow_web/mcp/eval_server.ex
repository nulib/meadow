defmodule MeadowWeb.MCP.EvalServer do
  @moduledoc "Eval-only MCP server. Exposes only read and submit-eval tools — never apply_work_metadata."

  alias MeadowWeb.MCP.{Resources, Tools}

  use Anubis.Server,
    name: "meadow-mcp-eval-server",
    version: "0.1.0",
    capabilities: [:resources, :tools]

  component(Resources.Schemas.Work)
  component(Resources.Schemas.FileSet)
  component(Tools.AuthoritySearch)
  component(Tools.GetIIIFImage)
  component(Tools.SubmitEvalMetadata)
end
