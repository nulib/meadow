defmodule Meadow.Chat.Publisher do
  @moduledoc """
  Publishes chat messages to subscriptions
  """

  def publish_message(conversation_id, type, message) do
    result = %{
      id: System.unique_integer([:positive]) |> to_string(),
      conversation_id: conversation_id,
      type: type,
      message: message
    }

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      result,
      chat_response: "conversation:#{conversation_id}"
    )
  end
end
