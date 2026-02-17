defmodule MeadowWeb.MCP.Tools.GetCodeList do
  @moduledoc """
  Return a list of valid codes for a given scheme.
  """

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.CodedTerms
  require Logger

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json"

  schema do
    field :scheme, :required,
      enum: CodedTerms.list_schemes(),
      description: "The code scheme to list codes for"
  end

  @impl true
  def execute(params, frame) do
    Logger.info("Executing get_code_list with scheme: #{params.scheme}")
    case CodedTerms.list_coded_terms(params.scheme) do
      [] ->
        {:error, MCPError.protocol(:invalid_params, %{error: "Unknown scheme", scheme: params.scheme}), frame}
      code_list ->
        result = Enum.map(code_list, & &1.id)
        {:reply, Response.tool() |> Response.json(result), frame}
    end
  end
end
