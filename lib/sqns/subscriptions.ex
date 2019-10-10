defmodule SQNS.Subscriptions do
  @moduledoc false

  alias ExAws.SNS
  alias SQNS.Utils.Arn
  alias SQNS.{Queues, Topics}
  require Logger

  def list_subscriptions(subscriptions \\ [], start_token \\ nil) do
    with %{body: result} <- SNS.list_subscriptions(start_token) |> ExAws.request!() do
      case Map.get(result, :next_token, "") do
        "" ->
          (subscriptions ++ result.subscriptions)
          |> Enum.filter(fn sub -> sub.protocol == "sqs" end)
          |> Enum.map(fn sub ->
            {
              Arn.parse(sub.topic_arn).resource,
              Arn.parse(sub.endpoint).resource,
              get_filter_policy(sub.subscription_arn)
            }
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

  def create_subscription({queue, topic, nil}, existing),
    do: create_subscription({queue, topic, %{}}, existing)

  def create_subscription({queue, topic, filter}, existing) do
    case existing |> Enum.find(&(&1 == {topic, queue, filter})) do
      nil ->
        Logger.info("Creating Subscription: #{topic} → #{queue}")
        topic_arn = topic |> Topics.get_topic_arn()
        queue_arn = queue |> Queues.get_queue_url() |> Queues.get_queue_arn()

        SNS.subscribe(topic_arn, "sqs", queue_arn)
        |> ExAws.request!()
        |> get_in([:body, :subscription_arn])
        |> set_filter(filter)

        {topic_arn, queue_arn, filter}

      {topic, queue, _} ->
        Logger.info("Subscription #{topic} → #{queue} already exists")
        :noop
    end
  end

  def create_subscription(spec), do: create_subscription(spec, list_subscriptions())

  defp get_filter_policy(subscription_arn) do
    case ExAws.SNS.get_subscription_attributes(subscription_arn)
         |> ExAws.request!()
         |> get_in([:body, :filter_policy]) do
      nil -> nil
      "" -> nil
      json -> Jason.decode!(json)
    end
  end

  defp set_filter(_, nil), do: :noop

  defp set_filter(subscription_arn, filter) do
    ExAws.SNS.set_subscription_attributes(
      :filter_policy,
      filter |> Jason.encode!(),
      subscription_arn
    )
    |> ExAws.request!()
  end
end
