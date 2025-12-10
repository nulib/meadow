defmodule MeadowWeb.MCP.ServerTest do
  use MeadowWeb.MCPCase, async: true

  describe "MCP Tool Discovery" do
    test "discover available tools" do
      response = list_tools()
      assert Map.has_key?(response, "tools")
      assert is_list(response["tools"])
    end
  end
end
