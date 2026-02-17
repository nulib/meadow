defmodule MeadowWeb.MCP.Tools.AuthoritySearchTest do
  use Meadow.AuthorityCase
  use MeadowWeb.MCPCase

  describe "Authority Search Tool" do
    test "execute an authority search" do
      {:ok, [{:text, response} | _]} =
        call_tool("authority_search", %{"authority_code" => "mock", "query" => "test"}) |> parse_response()

      assert result = Jason.decode!(response)
      assert is_list(result)
      assert length(result) == 5
    end

    test "execute an authority search with an invalid authority code" do
      {:error, error, _frame} =
        call_tool("authority_search", %{"authority_code" => "invalid", "query" => "test"})
      assert error.reason == :invalid_params
      assert error.data.message |> String.contains?("authority_code: expected one of")
      assert error.data.message |> String.contains?(~s'received "invalid"')
    end
  end
end
