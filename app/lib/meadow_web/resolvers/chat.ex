defmodule MeadowWeb.Resolvers.Chat do
  @moduledoc """
  Absinthe GraphQL query resolver for Chat Context

  """

  def send_chat_message(
        _,
        %{conversation_id: conversation_id, type: type, query: query, prompt: prompt},
        _
      ) do
    Task.start(fn ->
      {:ok, ai_response} = MeadowAI.query(prompt, context: %{query: query})

      response = %{
        conversation_id: conversation_id,
        message: ai_response,
        type: type
      }

      Absinthe.Subscription.publish(
        MeadowWeb.Endpoint,
        response,
        chat_response: "conversation:#{conversation_id}"
      )
    end)

    {:ok, %{conversation_id: conversation_id, type: type, query: query, prompt: prompt}}
  end
end
