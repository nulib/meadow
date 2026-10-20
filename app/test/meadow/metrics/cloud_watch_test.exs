defmodule Meadow.Metrics.CloudWatchTest do
  @moduledoc """
  Round trips real `PutMetricData` calls through Localstack.

  Everything else in the telemetry tests stops at the publisher boundary, which leaves
  the part most likely to be wrong untested: whether CloudWatch actually accepts the
  request body aws-elixir builds. `Values`/`Counts` arrays and the integer epoch
  `Timestamp` are both things the JSON protocol could plausibly reject, and a rejection
  would only ever show up where `:cloudwatch_publisher` is the real thing.

  These read the metrics back rather than trusting a 2xx, so a response that parsed none
  of the data would still fail.
  """
  use ExUnit.Case, async: false

  alias Meadow.AWS.Response
  alias Meadow.Metrics.{Aggregator, CloudWatch, Histogram}

  setup do
    Aggregator.reset()
    Application.put_env(:meadow, :metrics_probes, [])

    namespace = "Meadow/Test-#{Ecto.UUID.generate()}"
    Application.put_env(:meadow, :cloudwatch_namespace, namespace)

    on_exit(fn ->
      Aggregator.reset()
      Application.delete_env(:meadow, :cloudwatch_namespace)
      Application.delete_env(:meadow, :metrics_probes)
    end)

    {:ok, namespace: namespace}
  end

  defp publish do
    Aggregator.preview() |> CloudWatch.put_metric_data(150)
  end

  # ListMetrics omits "Dimensions" altogether for a metric that has none, rather than
  # returning an empty list, so normalize it back in.
  defp list_metrics(namespace) do
    Meadow.AWS.client(:cloudwatch)
    |> AWS.CloudWatch.list_metrics(%{"Namespace" => namespace})
    |> Response.unwrap()
    |> case do
      {:ok, %{"Metrics" => metrics}} ->
        Enum.map(metrics, &Map.put_new(&1, "Dimensions", []))

      {:ok, _} ->
        []

      other ->
        flunk("ListMetrics failed: #{inspect(other)}")
    end
  end

  # `Dimensions` is not a filter that can be omitted: CloudWatch treats a metric's
  # dimension set as part of its identity, so querying without them matches nothing rather
  # than aggregating across them. Rolling up across dimension values needs metric math or
  # a SEARCH() expression instead.
  defp statistics(namespace, metric_name, statistics, dimensions \\ []) do
    now = DateTime.utc_now()

    Meadow.AWS.client(:cloudwatch)
    |> AWS.CloudWatch.get_metric_statistics(%{
      "Namespace" => namespace,
      "MetricName" => metric_name,
      "Dimensions" => Enum.map(dimensions, fn {k, v} -> %{"Name" => k, "Value" => v} end),
      "StartTime" => now |> DateTime.add(-1, :hour) |> DateTime.to_unix(),
      "EndTime" => now |> DateTime.add(1, :hour) |> DateTime.to_unix(),
      "Period" => 60,
      "Statistics" => statistics
    })
    |> Response.unwrap()
    |> case do
      {:ok, %{"Datapoints" => datapoints}} -> datapoints
      other -> flunk("GetMetricStatistics failed: #{inspect(other)}")
    end
  end

  describe "put_metric_data/2" do
    test "CloudWatch accepts a counter", %{namespace: namespace} do
      Aggregator.count("round.trip.count", 3, Action: "RoundTrip", Outcome: "ok")

      assert publish() == :ok

      assert [%{"MetricName" => "round.trip.count", "Dimensions" => dimensions}] =
               list_metrics(namespace)

      assert Enum.sort_by(dimensions, & &1["Name"]) == [
               %{"Name" => "Action", "Value" => "RoundTrip"},
               %{"Name" => "Outcome", "Value" => "ok"}
             ]
    end

    test "CloudWatch accepts a histogram as Values/Counts", %{namespace: namespace} do
      # Three observations in two buckets. If the Values/Counts arrays were dropped or
      # misread, SampleCount would not come back as 3.
      Aggregator.observe("round.trip.duration", 5, Action: "RoundTrip")
      Aggregator.observe("round.trip.duration", 5, Action: "RoundTrip")
      Aggregator.observe("round.trip.duration", 5_000, Action: "RoundTrip")

      assert publish() == :ok

      statistics = ["SampleCount", "Sum", "Minimum", "Maximum"]

      assert [datapoint] =
               statistics(namespace, "round.trip.duration", statistics, [
                 {"Action", "RoundTrip"}
               ])

      # The three observations collapsed into two buckets before publishing. CloudWatch
      # getting SampleCount back as 3 is what proves it read the Counts array and weighted
      # the values by it, rather than treating Values as three... two datapoints.
      assert datapoint["SampleCount"] == 3.0
      assert datapoint["Unit"] == "Milliseconds"

      # Bucket bounds, not the raw measurements: 5ms and 5000ms round up to their √2
      # bucket's upper edge, and Sum is the bound-weighted total.
      [small, large] =
        [Histogram.index(5), Histogram.index(5_000)] |> Enum.map(&Histogram.bound/1)

      assert datapoint["Minimum"] == small * 1.0
      assert datapoint["Maximum"] == large * 1.0
      assert datapoint["Sum"] == (small * 2 + large) * 1.0
    end

    test "a gauge with no dimensions round trips", %{namespace: namespace} do
      Aggregator.gauge("round.trip.stalled", 7)

      assert publish() == :ok

      assert [%{"MetricName" => "round.trip.stalled", "Dimensions" => []}] =
               list_metrics(namespace)

      assert [%{"Maximum" => 7.0}] = statistics(namespace, "round.trip.stalled", ["Maximum"])
    end

    test "a dimensioned metric is only retrievable with its dimensions", %{
      namespace: namespace
    } do
      Aggregator.observe("round.trip.dimensioned", 5, Action: "RoundTrip")

      assert publish() == :ok

      assert statistics(namespace, "round.trip.dimensioned", ["SampleCount"]) == []

      assert [_] =
               statistics(namespace, "round.trip.dimensioned", ["SampleCount"], [
                 {"Action", "RoundTrip"}
               ])
    end

    test "publishing nothing is not an error" do
      assert CloudWatch.put_metric_data([], 150) == :ok
    end

    test "a batch larger than the chunk size is sent in several requests", %{
      namespace: namespace
    } do
      for n <- 1..20, do: Aggregator.count("round.trip.chunked", 1, Action: "Action#{n}")

      assert Aggregator.preview() |> CloudWatch.put_metric_data(5) == :ok

      assert list_metrics(namespace) |> length() == 20
    end
  end

  describe "namespace/0" do
    setup do
      # The outer setup pins an explicit namespace so each test gets its own; these cases
      # are about what the namespace resolves to when nothing pins it.
      Application.delete_env(:meadow, :cloudwatch_namespace)

      on_exit(fn ->
        Application.delete_env(:meadow, :cloudwatch_deployed_tenants)
        Application.delete_env(:meadow, :environment_prefix)
      end)
    end

    test "staging and production share a namespace, being in separate accounts" do
      Application.put_env(:meadow, :environment_prefix, "meadow")
      production = CloudWatch.namespace()

      Application.put_env(:meadow, :environment_prefix, "staging")
      staging = CloudWatch.namespace()

      assert production == "Meadow"
      assert staging == "Meadow"
    end

    test "a dev box does not collide with staging, which shares its account" do
      Application.put_env(:meadow, :environment_prefix, "staging")
      staging = CloudWatch.namespace()

      Application.put_env(:meadow, :environment_prefix, "mbk")
      dev = CloudWatch.namespace()

      assert dev == "Meadow/mbk"
      refute staging == dev
    end

    test "an unset tenant falls back to the bare namespace" do
      Application.delete_env(:meadow, :environment_prefix)
      assert CloudWatch.namespace() == "Meadow"

      Application.put_env(:meadow, :environment_prefix, "")
      assert CloudWatch.namespace() == "Meadow"
    end

    test "the tenants sharing the base namespace are configurable" do
      Application.put_env(:meadow, :cloudwatch_deployed_tenants, ~w(meadow staging demo))
      Application.put_env(:meadow, :environment_prefix, "demo")

      assert CloudWatch.namespace() == "Meadow"
    end
  end
end
