defmodule MeadowWeb.MCP.GraphQLTest do
  use MeadowWeb.MCPCase, async: true
  alias Meadow.Data.CodedTerms

  describe "GraphQL Tool" do
    test "execute a simple GraphQL query" do
      query = """
      query WhoAmi {
        me {
          displayName
        }
      }
      """

      assert {:ok, [{:text, text}]} =
               call_tool("graphql", %{"query" => query}) |> parse_response()

      assert response = Jason.decode!(text)
      assert get_in(response, ["me", "displayName"]) |> String.contains?("Test User")
    end

    test "execute a GraphQL query with variables" do
      query = """
      query CodeList($scheme: CodeListScheme!) {
        codeList(scheme:$scheme){
          id
          label
        }
      }
      """

      variables = %{"scheme" => "NOTE_TYPE"}

      assert {:ok, [{:text, text}]} =
               call_tool("graphql", %{"query" => query, "variables" => variables})
               |> parse_response()

      assert response = Jason.decode!(text)
      assert Map.has_key?(response, "codeList")
      assert length(response["codeList"]) == CodedTerms.list_coded_terms("note_type") |> length()
    end

    test "handle GraphQL errors gracefully" do
      query = """
      query InvalidQuery {
        invalidField {
          id
        }
      }
      """

      assert {:error, error} = call_tool("graphql", %{"query" => query}) |> parse_response()
      assert String.contains?(error, ~s{Cannot query field "invalidField"})
    end
  end
end
