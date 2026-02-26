defmodule MeadowWeb.Schema.Mutation.SendAgentLogTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.Data.Planner

  load_gql(MeadowWeb.Schema, "test/gql/SendAgentLog.gql")

  test "sends an agent log as editor" do
    {:ok, plan} = Planner.create_plan(%{prompt: "test prompt", query: "id:(test)"})
    Cachex.put!(Meadow.Cache.Chat.Conversations, plan.id, "test-conversation-123")

    result =
      query_gql(
        variables: %{
          "planId" => plan.id,
          "message" => "tool_call: mcp__meadow__get_work",
          "level" => "info"
        },
        context: gql_context(%{role: :editor, id: "meadow"})
      )

    assert {:ok, query_data} = result

    message = get_in(query_data, [:data, "sendAgentLog"])
    assert message["conversationId"] == "test-conversation-123"
    assert message["type"] == "agent_log"
    assert message["message"] == "tool_call: mcp__meadow__get_work"
    assert message["planId"] == plan.id
  end
end
