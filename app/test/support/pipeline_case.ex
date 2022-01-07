defmodule Meadow.PipelineCase do
  @moduledoc """
  This module includes the setup, teardown, and utility functions
  for working with Pipeline actions
  """

  use ExUnit.CaseTemplate
  alias Meadow.Pipeline.Action

  using do
    quote do
      import Meadow.PipelineCase
    end
  end

  def send_test_message(action, input, context \\ %{}) do
    with {_, message} <- action.sendable_message(input, context) do
      [%Broadway.Message{data: {data, attrs}}] =
        [%Broadway.Message{acknowledger: :ack, data: message}]
        |> action.prepare_messages(%{})

      Action.process(action, data, attrs)
    end
  end
end
