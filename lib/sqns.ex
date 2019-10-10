defmodule SQNS do
  alias SQNS.{Queues, Subscriptions, Topics}

  @moduledoc """
  Utilities to create the queues, topics, and subscriptions required to
  support the ingest pipeline.
  """

  @type stringish :: atom() | binary()
  @type filter :: {stringish(), stringish()}
  @type subscription :: stringish() | {stringish(), list(filter())}
  @type subscriptions :: list(subscription())
  @type spec :: stringish() | {stringish(), subscriptions()}
  @type specs :: list(spec)

  @doc "Set up pipeline infrastructure based on a list of queue/topic/subscription specs"
  @spec setup(specs :: specs()) :: {list(), list(), list()}
  def setup(specs) do
    (queues = parse_queues(specs)) |> Queues.create_queues()
    (topics = parse_topics(specs)) |> Topics.create_topics()
    (subscriptions = parse_subscriptions(specs)) |> Subscriptions.create_subscriptions()
    {queues, topics, subscriptions}
  end

  defp parse_queues(specs) do
    specs
    |> Enum.map(fn
      {queue, _} -> to_string(queue)
      queue -> to_string(queue)
    end)
  end

  defp parse_topics(specs), do: parse_queues(specs)

  defp parse_filters(filters) do
    filters
    |> Enum.map(fn
      {key, value} when is_list(value) -> {key, value}
      {key, value} -> {key, [value]}
    end)
    |> Enum.into(%{})
  end

  defp parse_subscriptions(specs) do
    specs
    |> Enum.filter(fn
      {_, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {queue, queue_subs} ->
      queue_subs
      |> Enum.map(fn
        {target, filters} ->
          {queue, target, filters |> parse_filters()}

        target ->
          {queue, target, nil}
      end)
    end)
    |> List.flatten()
  end
end
