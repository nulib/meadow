defmodule MeadowWeb.MCPCase do
  @moduledoc """
  This module defines the test case to be used by tests that require making requests
  to the MCP endpoint.
  """

  use ExUnit.CaseTemplate

  alias Anubis.Server.{Frame, Handlers}
  import Meadow.TestHelpers

  using do
    quote do
      use Meadow.DataCase
      import MeadowWeb.MCPCase
    end
  end

  @doc """
  Fetch the list of available MCP tools.
  """
  def list_tools do
    call_mcp("tools/list")
    |> Map.update("tools", [], fn tools ->
      Enum.map(tools, fn tool ->
        %{
          "name" => tool.name,
          "title" => tool.title,
          "description" => tool.description,
          "inputSchema" => tool.input_schema
        }
      end)
    end)
  end

  @doc """
  Call an MCP tool with the given name and parameters.
  """
  def call_tool(tool, params \\ %{}) do
    call_mcp("tools/call", %{
      "name" => tool,
      "arguments" => params
    })
  end

  @doc """
  Parse the response from an MCP tool call.

  Returns `{:ok, content}` or `{:error, reason}`, where `content` is a
  list of `{type, data}` tuples.
  """
  def parse_response(%{"isError" => true, "content" => [%{"text" => reason} | _]}),
    do: {:error, reason}

  def parse_response(%{"content" => content}) do
    {:ok,
     Enum.map(content, fn %{"type" => type} = item ->
       {String.to_atom(type), item[type]}
     end)}
  end

  defp call_mcp(method, params \\ %{}) do
    frame = Frame.new(current_user: user_fixture())
    request = %{"method" => method, "params" => params}
    {:reply, response, _frame} = Handlers.handle(request, MeadowWeb.MCP.Server, frame)
    response
  end
end
