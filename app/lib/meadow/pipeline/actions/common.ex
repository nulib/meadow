defmodule Meadow.Pipeline.Actions.Common do
  @moduledoc """
  Base implementation for Meadow pipeline actions
  """

  defmacro __using__(_) do
    quote do
      use Broadway
      use Meadow.Utils.Logging

      alias Broadway.Message
      alias Meadow.Pipeline.Action

      require Logger

      def start_link(opts), do: Action.start_link(__MODULE__, opts)

      @impl Broadway
      def handle_batch(:dispatch, messages, _, _), do: Action.handle_batch(__MODULE__, messages)

      @impl Broadway
      def handle_message(_, message, _), do: Action.handle_message(__MODULE__, message)

      @impl Broadway
      def prepare_messages(messages, _), do: Action.prepare_messages(__MODULE__, messages)

      def sendable_message(data, context \\ %{}),
        do: Action.sendable_message(__MODULE__, data, context)

      def send_message(data, context \\ %{}),
        do: Action.send_message(__MODULE__, data, context)

      def prepare_file_set_id(%Message{data: {%{file_set_id: _}, _}} = message), do: message
    end
  end
end
