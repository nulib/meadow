defmodule MeadowWeb.Schema.Subscription.ChatResponseTest do
  use Meadow.DataCase
  use MeadowWeb.SubscriptionCase, async: true

  @reply_timeout 5000

  load_gql(MeadowWeb.Schema, "test/gql/ChatResponse.gql")

  test "should initiate subscription as editor", %{socket: socket} do
    conversation_id = "test-conversation-123"
    ref = subscribe_gql(socket, variables: %{"conversationId" => conversation_id}, context: gql_context(%{role: :editor}))
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}, @reply_timeout
  end
end
