defmodule MeadowWeb.Resolvers.Chat do
  @moduledoc """
  Absinthe GraphQL query resolver for Chat Context

  """

  def send_chat_message(
        _,
        %{conversation_id: conversation_id, type: type, query: query, prompt: prompt},
        _
      ) do
    response = %{
      conversation_id: conversation_id,
      message: "Here is your plan....",
      type: "plan"
    }

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      response,
      chat_response: "conversation:#{conversation_id}"
    )

    {:ok, %{conversation_id: conversation_id, type: type, query: query, prompt: prompt}}
  end
end
