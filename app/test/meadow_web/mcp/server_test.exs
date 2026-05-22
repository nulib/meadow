defmodule MeadowWeb.MCP.ServerTest do
  use MeadowWeb.MCPCase, async: true

  describe "MCP Tool Discovery" do
    test "discover available tools" do
      response = list_tools()
      assert Map.has_key?(response, "tools")
      assert is_list(response["tools"])
    end

    test "eval server exposes only eval-safe tools" do
      tool_names =
        MeadowWeb.MCP.EvalServer
        |> list_tools()
        |> Map.fetch!("tools")
        |> Enum.map(& &1["name"])

      assert "authority_search" in tool_names
      assert "get_iiif_image" in tool_names
      assert "submit_eval_metadata" in tool_names

      refute "get_image" in tool_names
      refute "get_ingest_image" in tool_names
      refute "apply_work_metadata" in tool_names
    end
  end
end
