defmodule Meadow.Metrics.AggregatorTest do
  @moduledoc """
  The aggregator owns named ETS tables, so there is one instance per node and these tests
  share the one the application started. They run synchronously and reset it between
  cases rather than starting instances of their own.
  """
  use ExUnit.Case, async: false

  alias Meadow.Metrics.{Aggregator, Histogram}
  import Meadow.Metrics.Aggregator, only: [set_publisher: 1]

  defmodule TestPublisher do
    @moduledoc false
    @behaviour Meadow.Metrics.Publisher

    @impl true
    def put_metric_data(metric_data, chunk_size) do
      send(owner(), {:published, metric_data, chunk_size})
      :ok
    end

    def owner, do: :persistent_term.get({__MODULE__, :owner})
    def own, do: :persistent_term.put({__MODULE__, :owner}, self())
  end

  defmodule FailingPublisher do
    @moduledoc false
    @behaviour Meadow.Metrics.Publisher

    @impl true
    def put_metric_data(_metric_data, _chunk_size), do: {:error, :throttled}
  end

  setup do
    Aggregator.reset()

    # No probes: they query the database, and nothing here is testing them.
    previous_probes = Application.get_env(:meadow, :metrics_probes)
    Application.put_env(:meadow, :metrics_probes, [])

    on_exit(fn ->
      Aggregator.reset()
      set_publisher(nil)

      case previous_probes do
        nil -> Application.delete_env(:meadow, :metrics_probes)
        probes -> Application.put_env(:meadow, :metrics_probes, probes)
      end
    end)

    :ok
  end

  defp find(metric_data, name),
    do: Enum.find(metric_data, &(&1["MetricName"] == name))

  defp dimensions(datum),
    do: Enum.into(datum["Dimensions"], %{}, &{&1["Name"], &1["Value"]})

  describe "counters" do
    test "accumulate across calls" do
      Aggregator.count("pipeline.action.count", 1, Action: "ExtractMimeType", Outcome: "ok")
      Aggregator.count("pipeline.action.count", 2, Action: "ExtractMimeType", Outcome: "ok")

      assert %{"Value" => 3, "Unit" => "Count"} =
               Aggregator.preview() |> find("pipeline.action.count")
    end

    test "keep separate totals per dimension set" do
      Aggregator.count("pipeline.action.count", 1, Action: "ExtractMimeType", Outcome: "ok")
      Aggregator.count("pipeline.action.count", 5, Action: "ExtractMimeType", Outcome: "error")

      by_outcome =
        Aggregator.preview()
        |> Enum.filter(&(&1["MetricName"] == "pipeline.action.count"))
        |> Enum.into(%{}, &{dimensions(&1)["Outcome"], &1["Value"]})

      assert by_outcome == %{"ok" => 1, "error" => 5}
    end

    test "are keyed independently of the order dimensions are given in" do
      Aggregator.count("pipeline.action.count", 1, Action: "A", Outcome: "ok")
      Aggregator.count("pipeline.action.count", 1, Outcome: "ok", Action: "A")

      assert [%{"Value" => 2}] =
               Aggregator.preview() |> Enum.filter(&(&1["MetricName"] == "pipeline.action.count"))
    end
  end

  describe "histograms" do
    test "publish as Values/Counts so CloudWatch can calculate percentiles" do
      Enum.each([5, 5, 5_000], &Aggregator.observe("pipeline.action.duration", &1, Action: "A"))

      datum = Aggregator.preview() |> find("pipeline.action.duration")

      assert datum["Unit"] == "Milliseconds"
      assert Enum.sum(datum["Counts"]) == 3
      refute Map.has_key?(datum, "Value")
      refute Map.has_key?(datum, "StatisticValues")
    end

    test "collapse observations that share a bucket" do
      Enum.each([5, 5, 5], &Aggregator.observe("pipeline.action.duration", &1, Action: "A"))

      datum = Aggregator.preview() |> find("pipeline.action.duration")

      assert datum["Values"] == [Histogram.bound(Histogram.index(5))]
      assert datum["Counts"] == [3]
    end

    test "publish values in ascending order" do
      Enum.each([5_000, 5, 500], &Aggregator.observe("pipeline.action.duration", &1, Action: "A"))

      datum = Aggregator.preview() |> find("pipeline.action.duration")

      assert datum["Values"] == Enum.sort(datum["Values"])
    end

    test "stay within the 150 values CloudWatch accepts per datum" do
      Enum.each(1..5_000, &Aggregator.observe("pipeline.action.duration", &1, Action: "A"))

      datum = Aggregator.preview() |> find("pipeline.action.duration")

      assert length(datum["Values"]) <= 150
      assert Enum.sum(datum["Counts"]) == 5_000
    end
  end

  describe "gauges" do
    test "report the most recent value" do
      Aggregator.gauge("pipeline.transcode.stalled", 3)
      Aggregator.gauge("pipeline.transcode.stalled", 7)

      assert %{"Value" => 7} = Aggregator.preview() |> find("pipeline.transcode.stalled")
    end

    test "gauge_value/2 reports what is currently being published" do
      assert Aggregator.gauge_value("some.gauge") == nil

      Aggregator.gauge("some.gauge", 4)
      assert Aggregator.gauge_value("some.gauge") == 4
    end

    test "gauge_value/2 distinguishes a zero from an absent gauge" do
      Aggregator.gauge("some.gauge", 0)

      assert Aggregator.gauge_value("some.gauge") == 0
      refute Aggregator.gauge_value("some.gauge") == nil
    end

    test "clear_gauge/2 stops the metric being reported" do
      Aggregator.gauge("some.gauge", 4)
      assert Aggregator.clear_gauge("some.gauge") == :ok

      assert Aggregator.gauge_value("some.gauge") == nil
      refute Enum.find(Aggregator.preview(), &(&1["MetricName"] == "some.gauge"))
    end

    test "gauges with different dimensions are cleared independently" do
      Aggregator.gauge("some.gauge", 1, Action: "A")
      Aggregator.gauge("some.gauge", 2, Action: "B")

      Aggregator.clear_gauge("some.gauge", Action: "A")

      assert Aggregator.gauge_value("some.gauge", Action: "A") == nil
      assert Aggregator.gauge_value("some.gauge", Action: "B") == 2
    end

    test "carry the unit they were recorded with" do
      Aggregator.gauge("some.lag", 42, [], "Seconds")

      assert %{"Unit" => "Seconds"} = Aggregator.preview() |> find("some.lag")
    end
  end

  describe "preview/0" do
    test "does not drain what it reports" do
      Aggregator.count("pipeline.action.count", 4, Action: "A")

      assert %{"Value" => 4} = Aggregator.preview() |> find("pipeline.action.count")
      assert %{"Value" => 4} = Aggregator.preview() |> find("pipeline.action.count")
    end

    test "floors its timestamp to the minute so every node lands in the same period" do
      Aggregator.count("pipeline.action.count", 1, Action: "A")

      assert %{"Timestamp" => timestamp} = Aggregator.preview() |> find("pipeline.action.count")
      assert rem(timestamp, 60) == 0
    end

    test "is empty when nothing has been recorded" do
      assert Aggregator.preview() == []
    end
  end

  describe "flush/0" do
    test "drains counters and histograms" do
      Aggregator.count("pipeline.action.count", 4, Action: "A")
      Aggregator.observe("pipeline.action.duration", 10, Action: "A")

      assert %{metric_data: metric_data} = Aggregator.flush()
      assert find(metric_data, "pipeline.action.count")
      assert find(metric_data, "pipeline.action.duration")

      assert Aggregator.preview() == []
    end

    test "leaves gauges in place to be republished" do
      Aggregator.gauge("pipeline.transcode.stalled", 2)

      assert %{"Value" => 2} =
               Aggregator.flush().metric_data |> find("pipeline.transcode.stalled")

      assert %{"Value" => 2} =
               Aggregator.flush().metric_data |> find("pipeline.transcode.stalled")
    end

    test "keeps measurements recorded while the flush is building" do
      Aggregator.count("pipeline.action.count", 4, Action: "A")
      Aggregator.flush()
      Aggregator.count("pipeline.action.count", 1, Action: "A")

      assert %{"Value" => 1} = Aggregator.preview() |> find("pipeline.action.count")
    end
  end

  describe "with no publisher configured" do
    setup do
      set_publisher(nil)
      TestPublisher.own()
      :ok
    end

    test "still aggregates and still flushes on the same cycle" do
      Aggregator.count("pipeline.action.count", 3, Action: "A")

      assert %{published: false, metric_data: metric_data} = Aggregator.flush()
      assert %{"Value" => 3} = find(metric_data, "pipeline.action.count")
    end

    test "publishes nothing" do
      Aggregator.count("pipeline.action.count", 3, Action: "A")
      Aggregator.flush()

      refute_received {:published, _, _}
    end

    test "last_report/0 shows what would have been sent" do
      Aggregator.count("pipeline.action.count", 3, Action: "A")
      Aggregator.flush()

      assert %{published: false, metric_data: metric_data, flushed_at: %DateTime{}} =
               Aggregator.last_report()

      assert %{"Value" => 3} = find(metric_data, "pipeline.action.count")
    end
  end

  describe "with a publisher configured" do
    setup do
      set_publisher(TestPublisher)
      TestPublisher.own()
      :ok
    end

    test "publishes the batch and records that it went out" do
      Aggregator.count("pipeline.action.count", 3, Action: "A")

      assert %{published: true} = Aggregator.flush()
      assert_received {:published, metric_data, _chunk_size}
      assert %{"Value" => 3} = find(metric_data, "pipeline.action.count")
    end

    test "skips the call entirely when there is nothing to report" do
      assert %{published: false, metric_data: []} = Aggregator.flush()
      refute_received {:published, _, _}
    end

    test "a publish failure leaves the report marked unpublished" do
      set_publisher(FailingPublisher)
      Aggregator.count("pipeline.action.count", 1, Action: "A")

      assert %{published: false} = Aggregator.flush()
    end
  end
end
