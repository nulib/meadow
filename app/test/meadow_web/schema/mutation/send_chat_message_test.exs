defmodule MeadowWeb.Schema.Mutation.SendChatMessageTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/SendChatMessage.gql")

  test "should send a chat message as editor" do
    result =
      query_gql(
        variables: %{
          "conversationId" => "test-conversation-123",
          "type" => "chat",
          "query" => "test query",
          "prompt" => "test prompt"
        },
        context: gql_context(%{role: :editor})
      )

    assert {:ok, query_data} = result

    message = get_in(query_data, [:data, "sendChatMessage"])

    assert message["conversationId"] == "test-conversation-123"
    assert message["type"] == "chat"
    assert message["query"] == "test query"
    assert message["prompt"] == "test prompt"
  end

  test "should reject unauthorized users" do
    result =
      query_gql(
        variables: %{
          "conversationId" => "test-conversation-123",
          "type" => "chat",
          "query" => "test query",
          "prompt" => "test prompt"
        },
        context: gql_context(%{role: :user})
      )

    assert {:ok, query_data} = result
    assert get_in(query_data, [:errors]) != nil
  end
end
