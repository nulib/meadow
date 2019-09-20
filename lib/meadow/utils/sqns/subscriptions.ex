defmodule Meadow.Utils.SQNS.Subscriptions do
  @moduledoc false

  alias ExAws.SNS
  alias Meadow.Utils.Arn
  alias Meadow.Utils.SQNS.{Queues, Topics}
  require Logger

  def list_subscriptions(subscriptions \\ [], start_token \\ nil) do
    with %{body: result} <- SNS.list_subscriptions(start_token) |> ExAws.request!() do
      case Map.get(result, :next_token, "") do
        "" ->
          (subscriptions ++ result.subscriptions)
          |> Enum.filter(fn sub -> sub.protocol == "sqs" end)
          |> Enum.map(fn sub ->
            {Arn.parse(sub.topic_arn).resource, Arn.parse(sub.endpoint).resource}
          end)

        token ->
          list_subscriptions(subscriptions ++ result.subscriptions, token)
      end
    end
  end

  def create_subscriptions(subscriptions) do
    existing = list_subscriptions()

    subscriptions
    |> Enum.each(fn sub -> create_subscription(sub, existing) end)
  end

  def create_subscription({topic, queue} = sub, existing) do
    case existing |> Enum.find(&(&1 == sub)) do
      nil ->
        Logger.info("Creating Subscription: #{topic} → #{queue}")
        topic_arn = topic |> Topics.get_topic_arn()
        queue_arn = queue |> Queues.get_queue_url() |> Queues.get_queue_arn()

        SNS.subscribe(topic_arn, "sqs", queue_arn)
        |> ExAws.request!()

        {topic_arn, queue_arn}

      {topic, queue} ->
        Logger.info("Subscription #{topic} → #{queue} already exists")
        :noop
    end
  end

  def create_subscription(spec), do: create_subscription(spec, list_subscriptions())
end
