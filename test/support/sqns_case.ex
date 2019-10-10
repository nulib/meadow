defmodule SQNS.TestCase do
  use ExUnit.CaseTemplate

  @moduledoc """
  Test case for testing SQNS resources
  """

  using do
    quote do
      setup do
        sqns_state = [
          topics: SQNS.Topics.list_topics(),
          queues: SQNS.Queues.list_queues(),
          topic_names: SQNS.Topics.list_topic_names(),
          queue_names: SQNS.Queues.list_queue_names(),
          subscriptions: SQNS.Subscriptions.list_subscriptions()
        ]

        on_exit(fn ->
          topics(%{sqns_state: sqns_state})
          |> Enum.each(fn t -> ExAws.SNS.delete_topic(t) |> ExAws.request!() end)

          queues(%{sqns_state: sqns_state})
          |> Enum.each(fn q -> ExAws.SQS.delete_queue(q) |> ExAws.request!() end)
        end)

        {:ok, sqns_state: sqns_state}
      end

      def queues(c), do: SQNS.Queues.list_queues() -- c[:sqns_state][:queues]
      def queue_names(c), do: SQNS.Queues.list_queue_names() -- c[:sqns_state][:queue_names]
      def topics(c), do: SQNS.Topics.list_topics() -- c[:sqns_state][:topics]
      def topic_names(c), do: SQNS.Topics.list_topic_names() -- c[:sqns_state][:topic_names]

      def subscriptions(c),
        do: SQNS.Subscriptions.list_subscriptions() -- c[:sqns_state][:subscriptions]
    end
  end
end
