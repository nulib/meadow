defmodule MeadowWeb.Schema.Types.Data.Chat do
  @moduledoc """
  Absinthe schema for Chat and ChatMessage types
  """
  use Absinthe.Schema.Notation

  alias MeadowWeb.Resolvers

  object :chat_subscriptions do
    field :chat_response, :chat_message do
      arg :conversation_id, non_null(:id)

      config fn args, _context ->
        {:ok, topic: "conversation:#{args.conversation_id}"}
      end

      trigger [:send_chat_message], topic: fn
        %{conversation_id: conversation_id} -> ["conversation:#{conversation_id}"]
        _ -> []
      end
    end
  end

  object :chat_mutations do
    field :send_chat_message, type: :chat_message do
      arg :conversation_id, non_null(:id)
      arg :type, non_null(:string)
      arg :message, non_null(:string)

      resolve &Resolvers.Chat.send_chat_message/3
    end
  end



  object :chat_message do
    field :id, :id
    field :conversation_id, :id
    field :type, :string
    field :message, :string
    field :inserted_at, :naive_datetime
  end

end
