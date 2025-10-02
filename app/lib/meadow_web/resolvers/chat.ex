defmodule MeadowWeb.Resolvers.Chat do

  @moduledoc """
  Absinthe GraphQL query resolver for Chat Context

  """

  def send_chat_message(_, %{conversation_id: conversation_id, type: type, message: message}, _) do
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

    {:ok, result}
  end
end
