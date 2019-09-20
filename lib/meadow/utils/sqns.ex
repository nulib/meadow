defmodule Meadow.Utils.SQNS do
  alias Meadow.Utils.SQNS.{Queues, Subscriptions, Topics}

  @moduledoc """
  Utilities to create the queues, topics, and subscriptions required to
  support the ingest pipeline.
  """

  @type subs :: [ok: binary() | list(binary()), error: binary() | list(binary())]
  @type spec :: binary() | {binary(), subs()}
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

  defp parse_topics(specs) do
    parse_queues(specs)
    |> Enum.reduce([], fn queue, acc ->
      acc ++ ["#{queue}-ok", "#{queue}-error"]
    end)
  end

  defp parse_subscription(queue, target, status), do: {"#{queue}-#{status}", to_string(target)}

  defp parse_subscriptions(specs) do
    specs
    |> Enum.filter(fn
      {_, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {queue, queue_subs} ->
      queue_subs
      |> Enum.map(fn
        {status, targets} when is_list(targets) ->
          targets
          |> Enum.map(&parse_subscription(queue, &1, status))

        {status, target} ->
          parse_subscription(queue, target, status)
      end)
    end)
    |> List.flatten()
  end
end
