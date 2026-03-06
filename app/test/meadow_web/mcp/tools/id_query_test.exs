defmodule MeadowWeb.MCP.Tools.IDQueryTest do
  use MeadowWeb.MCPCase
  use Meadow.IndexCase

  alias Meadow.Data.Indexer

  describe "ID Query Tool" do
    setup do
      1..37
      |> Enum.each(&work_fixture(%{accession_number: "TEST_WORK_#{&1}"}))

      Indexer.synchronize_index()
      :ok
    end

    test "execute an ID query with a valid OpenSearch query" do
      query = Jason.encode!(%{query: %{match_all: %{}}})

      {:ok, [{:text, response} | _]} =
        call_tool("id_query", %{"query" => query}) |> parse_response()

      assert result = Jason.decode!(response)
      assert ids = result["ids"]
      assert is_list(ids)
      assert length(ids) == 37
    end

    test "execute an ID query with an invalid OpenSearch query" do
      query = Jason.encode!(%{qury: %{invalid: %{}}})

      assert {:error, error, _frame} =
               call_tool("id_query", %{"query" => query}) |> parse_response()
      assert error.reason == :execution_error
      assert error.message == "Query must contain a 'query' field"
    end
  end
end
