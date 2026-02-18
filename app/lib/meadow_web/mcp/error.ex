defmodule MeadowWeb.MCP.Error do
  @moduledoc "Helper functions for generating MCP error responses."

  alias Anubis.Server.Response
  require Logger

  def error_response(tool, frame, error) do
    Logger.error("Unexpected error in #{tool.name()}: #{inspect(error)}")
    {:reply, Response.tool() |> Response.error("Unexpected error: #{inspect(error)}"), frame}
  end
end
