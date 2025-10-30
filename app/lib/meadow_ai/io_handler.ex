defmodule MeadowAI.IOHandler do
  @moduledoc """
  An IO handler for capturing and processing messages from the MeadowAI Python agent.
  """

  use GenServer

  require Logger

  def open(metadata \\ []) do
    GenServer.start(__MODULE__, metadata: metadata)
  end

  @impl true
  def init(opts \\ []) do
    metadata =
      Keyword.get(opts, :metadata, [])
      |> Keyword.put_new(:module, __MODULE__)
    Logger.metadata(metadata)
    {:ok, %{buffer: ""}}
  end

  @impl true
  def handle_info({:io_request, from, reply_as, {:put_chars, _encoding, chars}}, state) do
    buffer = process_messages(state.buffer <> chars)

    send(from, {:io_reply, reply_as, :ok})
    {:noreply, %{state | buffer: buffer}}
  end

  def handle_info({:io_request, from, reply_as, _request}, state) do
    send(from, {:io_reply, reply_as, {:error, :request}})
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info(message, state) do
    Logger.warning("Unhandled IO message: #{message}")
    {:noreply, state}
  end

  defp process_messages(buffer) do
    {remaining, messages} =
      buffer
      |> String.split("\n")
      |> List.pop_at(-1)

    messages
    |> Enum.each(fn line ->
      Jason.decode(line)
      |> handle_json()
    end)

    remaining
  end

  defp handle_json({:ok, %{"action" => "emit", "data" => message}}) do
    handle_message(message)
  end

  defp handle_json({:error, reason}) do
    Logger.error("Failed to decode JSON message: #{inspect(reason)}")
  end

  defp handle_json(_other), do: :noop

  # handle_message/1 implementations match specific message types
  # and structures and deal with them accordingly. Right now that
  # means logging them at appropriate levels, but it could also
  # include sending channel notifications, logging metrics,
  # storing in a database, etc. `Logger.metadata()` can be used
  # to access context such as the plan_id.

  defp handle_message(%{"type" => "debug", "message" => message}) do
    Logger.debug(message)
  end

  defp handle_message(%{"type" => "info", "message" => message}) do
    Logger.info(message)
  end

  defp handle_message(%{"type" => "usage", "message" => message}) do
    Logger.info("Token and Cost Info:\n#{format_message(message)}")
  end

  defp handle_message(%{"type" => "text", "message" => message}) do
    Logger.notice(message)
  end

  defp handle_message(%{"type" => "tool_result", "message" => message}) do
    message = case Jason.decode(message) do
      {:ok, decoded} -> decoded
      {:error, _} -> message
    end

    Logger.info("Tool Result:\n#{format_message(message)}")
  end

  defp handle_message(%{"type" => "raw_message", "message" => message}) do
    Logger.info("Raw Message:\n#{format_message(message)}")
  end

  defp handle_message(%{"type" => type, "message" => message}) do
    Logger.info("Received Message of type #{type}:\n#{format_message(message)}")
  end

  defp format_message(message) do
    inspect(message, pretty: true, limit: :infinity)
  end
end
