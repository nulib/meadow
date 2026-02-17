defmodule MeadowWeb.MCP.Tools.AuthoritySearch do
  @moduledoc """
  Return a work resource
  """

alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  require Logger

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json",
    description: "Search an authority for a term matching the provided query."

  schema do
    field :query, :string, required: true,
      description: "The search query to send to the authority (e.g. 'Shakespeare')"

    field :authority_code, :required,
      description: "The code for the authority to search (e.g. 'lcsh')",
      enum: Authoritex.authorities() |> Enum.map(fn {_, code, _} -> code end)
  end

  @impl true
  def execute(params, frame) do
    Logger.info("Executing authority search of `#{params.authority_code}` with query: `#{params.query}`")
    case Authoritex.search(params.authority_code, params.query) do
      {:ok, result} ->
        {:reply, Response.tool() |> Response.json(result), frame}
      {:error, "Unknown authority:" <> _} ->
        {:error, MCPError.protocol(:invalid_params, %{error: "Unknown authority", authority_code: params.authority_code}), frame}
      {:error, reason} ->
        {:error, MCPError.protocol(:internal_error, %{error: reason}), frame}
    end
  end
end
