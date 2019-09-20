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
  alias Meadow.Utils.SQNS

  @passthru "receiver"

  setup context do
    %{body: %{queue_url: queue_url}} = ExAws.SQS.create_queue(@passthru) |> ExAws.request!()

    with {_queues, topics, _subscriptions} <- context |> Map.get(:pipeline, []) |> SQNS.setup() do
      topics
      |> Enum.each(fn topic ->
        SQNS.Subscriptions.create_subscription({topic, @passthru})
      end)
    end

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

  @doc false
  def listen(pid) do
    pass_messages(pid)

    receive do
      :shutdown -> flush(pid)
    after
      250 -> listen(pid)
    end
  end

  defp teardown(queue) do
    ExAws.SNS.delete_topic(SQNS.Topics.get_topic_arn("#{queue}-ok")) |> ExAws.request()
    ExAws.SNS.delete_topic(SQNS.Topics.get_topic_arn("#{queue}-error")) |> ExAws.request()
    ExAws.SQS.delete_queue(SQNS.Queues.get_queue_url(queue)) |> ExAws.request()
  end

  defp pass_messages(pid) do
    queue_url = SQNS.Queues.get_queue_url(@passthru)

    case ExAws.SQS.receive_message(queue_url) |> ExAws.request!() do
      %{body: %{messages: []}} ->
        :ok

      %{body: %{messages: messages}} ->
        messages
        |> Enum.each(fn %{body: body, receipt_handle: handle} ->
          pass_message(body, pid)

          ExAws.SQS.delete_message(queue_url, handle)
          |> ExAws.request!()
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
end
