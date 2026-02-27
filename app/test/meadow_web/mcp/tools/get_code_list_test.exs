defmodule MeadowWeb.MCP.Tools.GetCodeListTest do
  use MeadowWeb.MCPCase

  describe "Get Code List Tool" do
    test "retrieve a code list" do
      {:ok, [{:text, response} | _]} =
        call_tool("get_code_list", %{"scheme" => "note_type"}) |> parse_response()

      assert result = Jason.decode!(response)
      assert is_list(result)
      assert Enum.member?(result, "GENERAL_NOTE")
      assert Enum.member?(result, "STATEMENT_OF_RESPONSIBILITY")
    end

    test "retrieve a code list with an invalid scheme" do
      {:error, error, _frame} =
        call_tool("get_code_list", %{"scheme" => "invalid"})
      assert error.reason == :invalid_params
      assert error.data.message |> String.contains?("scheme: expected one of")
      assert error.data.message |> String.contains?(~s'received "invalid"')
    end
  end
end
