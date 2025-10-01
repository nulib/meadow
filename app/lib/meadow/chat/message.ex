defmodule Meadow.Chat.Message do
  @moduledoc """
  Struct for chat messages
  """

  defstruct id: nil,
            conversation_id: nil,
            type: nil,
            message: nil,
            inserted_at: nil
end
