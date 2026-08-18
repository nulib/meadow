defmodule Meadow.AWS.SQS do
  @moduledoc """
  The SQS operations Meadow performs itself: sending pipeline messages and managing
  queues.

  Receiving is still BroadwaySQS's job, and BroadwaySQS still uses ExAws for it. Note
  that aws-elixir speaks SQS's JSON protocol rather than the older XML query protocol
  ExAws used, so inputs are maps keyed by the documented API parameter names.
  """

  # `AWS.SQS` is aws-elixir's generated module; Meadow.AWS is spelled out in full so the
  # two don't collide.
  alias Meadow.AWS.Response

  @doc """
  Look up a queue's URL by name.
  """
  def queue_url(queue_name) do
    Meadow.AWS.client(:sqs)
    |> AWS.SQS.get_queue_url(%{"QueueName" => queue_name})
    |> Response.unwrap(&Map.get(&1, "QueueUrl"))
  end

  def queue_url!(queue_name), do: unwrap_bang(queue_url(queue_name))

  @doc """
  Send a message body to a queue URL.
  """
  def send_message(url, body) do
    Meadow.AWS.client(:sqs)
    |> AWS.SQS.send_message(%{"QueueUrl" => url, "MessageBody" => body})
    |> Response.unwrap()
  end

  def send_message!(url, body), do: unwrap_bang(send_message(url, body))

  @doc """
  Create a queue, returning its URL. Creating an existing queue with the same
  attributes is a no-op on AWS's side.
  """
  def create_queue(queue_name, attributes \\ %{}) do
    input = %{"QueueName" => queue_name, "Attributes" => attributes}

    Meadow.AWS.client(:sqs)
    |> AWS.SQS.create_queue(input)
    |> Response.unwrap(&Map.get(&1, "QueueUrl"))
  end

  def create_queue!(queue_name, attributes \\ %{}),
    do: unwrap_bang(create_queue(queue_name, attributes))

  @doc """
  Delete every message in a queue.
  """
  def purge_queue(url) do
    Meadow.AWS.client(:sqs)
    |> AWS.SQS.purge_queue(%{"QueueUrl" => url})
    |> Response.unwrap_status()
  end

  def purge_queue!(url), do: unwrap_bang(purge_queue(url))

  defp unwrap_bang(:ok), do: :ok
  defp unwrap_bang({:ok, value}), do: value

  defp unwrap_bang({:error, reason}),
    do: raise(Meadow.AWS.Error, message: "SQS request failed: #{inspect(reason)}")
end
