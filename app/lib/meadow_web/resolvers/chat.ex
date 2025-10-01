defmodule MeadowWeb.Resolvers.Chat do

  @moduledoc """
  Absinthe GraphQL query resolver for Chat Context

  """

  def send_chat_message(_, %{conversation_id: conversation_id, type: type, message: message}, _) do
    {:ok, message}
  end
end
