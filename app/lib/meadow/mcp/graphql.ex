defmodule Meadow.MCP.GraphQL do
  @moduledoc """
  Execute GraphQL queries against the Meadow API.
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "graphql",
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  require Logger

  schema do
    field(:query, :string, description: "The GraphQL query string.")

    field(:variables, :map,
      description: "A map of variables for the query (optional).",
      default: %{}
    )
  end

  def name, do: "graphql"

  @impl true
  def execute(request, frame) do
    query = Map.get(request, :query)
    variables = Map.get(request, :variables, %{})
    context = %{current_user: frame.assigns[:current_user]}
    Logger.debug("MCP Server received GraphQL query: #{query}")

    case run_query(query, variables, context) do
      {:ok, data} ->
        {:reply, Response.tool() |> Response.json(data), frame}

      {:error, reason} ->
        {:error, MCPError.execution(reason), frame}
    end
  end

  defp run_query(query, variables, context) do
    case Absinthe.run(query, MeadowWeb.Schema, variables: variables, context: context) do
      {:ok, %{errors: [%{message: reason} | _]}} -> {:error, reason}
      {:ok, %{data: data}} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end
end
