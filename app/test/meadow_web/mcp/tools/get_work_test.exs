defmodule MeadowWeb.MCP.Tools.GetWorkTest do
  use MeadowWeb.MCPCase

  describe "Get Work Tool" do
    setup do
      work = work_fixture(%{descriptive_metadata: %{title: "Test Work"}})
      {:ok, work: work}
    end

    test "get a work", %{work: work} do
      {:ok, [{:text, response} | _]} =
        call_tool("get_work", %{"work_id" => work.id}) |> parse_response()

      assert result = Jason.decode!(response)
      assert is_map(result)
      assert result["id"] == work.id
      assert get_in(result, ["descriptive_metadata", "title"]) == "Test Work"
    end

    test "get a work with an invalid id" do
      bad_id = Ecto.UUID.generate()
      {:error, error, _frame} =
        call_tool("get_work", %{"work_id" => bad_id}) |> parse_response()
      assert error.reason == :resource_not_found
    end
  end
end
