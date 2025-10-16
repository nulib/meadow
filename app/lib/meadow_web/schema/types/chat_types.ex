defmodule MeadowWeb.Schema.ChatTypes do
  @moduledoc """
  Absinthe schema for Chat and ChatMessage types
  """
  use Absinthe.Schema.Notation

  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :chat_subscriptions do
    field :chat_response, :chat_response do
      arg(:conversation_id, non_null(:id))

      config(fn args, _ ->
        {:ok, topic: "conversation:#{args.conversation_id}"}
      end)
    end
  end

  object :chat_mutations do
    field :send_chat_message, type: :chat_message do
      arg(:conversation_id, non_null(:id))
      arg(:type, non_null(:string))
      arg(:query, non_null(:string))
      arg(:prompt, non_null(:string))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")

      resolve(&Resolvers.Chat.send_chat_message/3)
    end
  end

  object :chat_message do
    field(:conversation_id, :id, description: "Ref for the conversation")
    field(:type, :string, description: "Type of message, e.g. 'chat'")
    field(:query, :string, description: "The search query associated with the message")
    field(:prompt, :string, description: "The prompt associated with the message")
  end

  object :chat_response do
    field(:conversation_id, :id)
    field(:type, :string, description: "Type of message, e.g. 'chat'")
    field(:message, :string, description: "AI response message")
    field(:plan_id, :id, description: "The ID of the plan created for this chat message")
  end
end
