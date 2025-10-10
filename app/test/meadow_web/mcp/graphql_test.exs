defmodule MeadowWeb.MCP.GraphQLTest do
  use MeadowWeb.MCPCase, async: true
  alias Meadow.Data.CodedTerms

  describe "GraphQL Tool" do
    setup do
      user = user_fixture()
      {:ok, %{user: user}}
    end

    test "execute a simple GraphQL query", %{user: user} do
      query = """
      query WhoAmi {
        me {
          displayName
        }
      }
      """

      assert {:ok, [{:text, text}]} =
               call_tool("graphql", %{"query" => query}, current_user: user) |> parse_response()

      assert response = Jason.decode!(text)
      assert get_in(response, ["me", "displayName"]) |> String.contains?(user.display_name)
    end

    test "execute a GraphQL query with variables", %{user: user} do
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
               call_tool("graphql", %{"query" => query, "variables" => variables},
                 current_user: user
               )
               |> parse_response()

      assert response = Jason.decode!(text)
      assert Map.has_key?(response, "codeList")
      assert length(response["codeList"]) == CodedTerms.list_coded_terms("note_type") |> length()
    end

    test "handle GraphQL errors gracefully", %{user: user} do
      query = """
      query InvalidQuery {
        invalidField {
          id
        }
      }
      """

      assert {:error, error} =
               call_tool("graphql", %{"query" => query}, current_user: user) |> parse_response()

      assert String.contains?(error, ~s{Cannot query field "invalidField"})
    end
  end
end
