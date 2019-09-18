defmodule Meadow.PipelineCase do
  @moduledoc ~S"""
  This module defines the setup for tests involving
  pipelines and actions.

  To set up queues and subscriptions for a test, use the
  `pipeline` tag, e.g.:

      @tag pipeline: [
        "queue-1": [error: "queue-3"],
        "queue-2": [ok: "queue-1", error: "queue-3"],
        "queue-3"
      ]

  The above example creates the SQS queues and SNS topics required to support 3 actions.
  It also sets up subscriptions so that `queue-1` will receive `:ok` results from `queue-2`,
  and `queue-3` will receive `:error` results from both `queue-1` and `queue-2`.
  """

  use ExUnit.CaseTemplate

  @queue_prefix "http://sqs.us-east-1.goaws.com:4100/100010001000/"
  @topic_prefix "arn:aws:sns:us-east-1:100010001000:"
  @passthru "receiver"

  setup context do
    context |> Map.get(:pipeline, []) |> create_queues() |> create_subscriptions()
    %{body: %{queue_url: queue_url}} = ExAws.SQS.create_queue(@passthru) |> ExAws.request!()

    receiver_listener = Task.async(Meadow.PipelineCase, :listen, [self()])

    on_exit(fn ->
      send(receiver_listener.pid, :shutdown)

      context
      |> Map.get(:pipeline, [])
      |> Enum.each(fn
        {queue, _} -> teardown(queue)
        queue -> teardown(queue)
      end)
    end)

    {
      :ok,
      %{receiver: queue_url}
    }
  end

  @doc """
  Send a message to the named queue, presumably to kickstart the
  action or pipeline being tested.
  """
  def send_message(queue, message) do
    queue
    |> test_queue_url()
    |> ExAws.SQS.send_message(message)
    |> ExAws.request!()
  end

  @doc false
  def listen(pid) do
    pass_messages(pid)

    receive do
      :shutdown -> flush(pid)
    after
      250 -> listen(pid)
    end
  end

  defp create_queues(specs) do
    specs
    |> Enum.each(fn spec ->
      {_queue, ok, error} =
        case spec do
          {queue, _} -> create_queue(queue)
          queue -> create_queue(queue)
        end

      subscribe(test_queue_url(@passthru), ok)
      subscribe(test_queue_url(@passthru), error)
    end)

    specs
  end

  defp create_subscriptions(specs) do
    specs
    |> Enum.each(fn
      {queue, subscriptions} ->
        subscriptions
        |> Enum.each(fn {status, topic} ->
          subscribe(test_queue_url(queue), test_topic_arn(topic, status))
        end)

      _ ->
        :noop
    end)

    specs
  end

  defp teardown(queue) do
    ExAws.SNS.delete_topic(test_topic_arn(queue, :ok)) |> ExAws.request()
    ExAws.SNS.delete_topic(test_topic_arn(queue, :error)) |> ExAws.request()
    ExAws.SQS.delete_queue(test_queue_url(queue)) |> ExAws.request()
  end

  defp pass_messages(pid) do
    case ExAws.SQS.receive_message(test_queue_url(@passthru)) |> ExAws.request!() do
      %{body: %{messages: []}} ->
        :ok

      %{body: %{messages: messages}} ->
        messages
        |> Enum.each(fn %{body: body, receipt_handle: handle} ->
          pass_message(body, pid)
          ExAws.SQS.delete_message(test_queue_url(@passthru), handle) |> ExAws.request!()
        end)

        :more
    end
  end

  defp pass_message(body, pid) do
    with %{"Message" => data, "TopicArn" => source} <- Jason.decode!(body) do
      status = source |> String.split("-") |> List.last() |> String.to_atom()
      send(pid, {status, data |> Jason.decode!()})
    end
  end

  defp flush(pid) do
    case pass_messages(pid) do
      :more -> flush(pid)
      :ok -> :ok
    end
  end

  defp create_queue(name) do
    %{body: %{queue_url: queue_url}} = ExAws.SQS.create_queue("#{name}") |> ExAws.request!()

    %{body: %{topic_arn: ok_topic}} = ExAws.SNS.create_topic("#{name}-ok") |> ExAws.request!()

    %{body: %{topic_arn: error_topic}} =
      ExAws.SNS.create_topic("#{name}-error") |> ExAws.request!()

    {queue_url, ok_topic, error_topic}
  end

  defp subscribe(queue_url, topic_arn) do
    ExAws.SNS.subscribe(topic_arn, "sqs", queue_url) |> ExAws.request!()
    :ok
  end

  defp test_queue_url(name), do: "#{@queue_prefix}#{name}"
  defp test_topic_arn(name, status), do: "#{@topic_prefix}#{name}-#{status}"
end
