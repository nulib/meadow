defmodule Meadow.Metrics.Aggregator do
  @moduledoc """
  Accumulates telemetry measurements in ETS and flushes aggregates to CloudWatch once a
  minute.

  Telemetry handlers run inline in the process that emitted the event, which for pipeline
  events is a Broadway processor. Rather than sending one message per event to this
  GenServer, handlers write straight to a public ETS table with `:ets.update_counter/4`,
  which is atomic and lock-free. The GenServer owns the tables and does nothing but flush
  on a timer, so a slow or wedged CloudWatch call can never back-pressure the pipeline.

  ## Why there is no cross-node aggregation

  CloudWatch merges every datapoint published for the same metric name, dimension set and
  period into that period's statistics. Each node can therefore publish its own local
  aggregate for the same minute and `Sum`, `SampleCount`, `Min`, `Max` and percentiles all
  come out globally correct, with no coordination between nodes. That is also why no
  metric here carries a node or host dimension: adding one would multiply the billed
  metric count by the number of running tasks and give up the free merge.

  ## Flushing when CloudWatch is disabled

  Aggregation and the flush cycle run regardless of whether publishing is on. When
  it is off the batch is built as usual and retained rather than published, so
  `last_report/0` shows exactly what would have been sent. `preview/0` builds the
  same structure from whatever has accumulated since the last flush without draining it.
  """

  use GenServer

  alias Meadow.Metrics.Histogram

  require Logger

  @counters :meadow_telemetry_counters
  @gauges :meadow_telemetry_gauges
  @flush_interval 60_000

  # CloudWatch accepts 1000 metric data per request within a 1MB payload. A datum
  # carrying a full histogram runs about 1KB of JSON, so chunking well below the item
  # limit keeps requests comfortably inside the size limit too.
  @chunk_size 150

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Record a duration measurement, in milliseconds, into the histogram for `name`.
  """
  @spec observe(String.t(), number(), keyword() | map()) :: :ok
  def observe(name, milliseconds, dimensions \\ []) do
    key = {:hist, name, normalize_dimensions(dimensions), Histogram.index(milliseconds)}
    increment(key, 1)
  end

  @doc """
  Add `n` to the counter for `name`.
  """
  @spec count(String.t(), number(), keyword() | map()) :: :ok
  def count(name, n \\ 1, dimensions \\ []) do
    increment({:count, name, normalize_dimensions(dimensions)}, n)
  end

  @doc """
  Set the current value of the gauge for `name`.

  Unlike counters, gauges are not drained on flush — the most recent value is published
  every minute until it is replaced.
  """
  @spec gauge(String.t(), number(), keyword() | map(), String.t()) :: :ok
  def gauge(name, value, dimensions \\ [], unit \\ "Count") do
    :ets.insert(@gauges, {{name, normalize_dimensions(dimensions)}, value, unit})
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  The current value of a gauge, or `nil` if it is not being reported.

  Lets a caller see what it last published, which is what makes it possible to tell a
  gauge that has gone quiet from one that was never set.
  """
  @spec gauge_value(String.t(), keyword() | map()) :: number() | nil
  def gauge_value(name, dimensions \\ []) do
    case :ets.lookup(@gauges, {name, normalize_dimensions(dimensions)}) do
      [{_key, value, _unit}] -> value
      _ -> nil
    end
  rescue
    ArgumentError -> nil
  end

  @doc """
  Stop reporting a gauge.

  The metric simply stops receiving datapoints, which is also how it stops being billed.
  """
  @spec clear_gauge(String.t(), keyword() | map()) :: :ok
  def clear_gauge(name, dimensions \\ []) do
    :ets.delete(@gauges, {name, normalize_dimensions(dimensions)})
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  The metric data that would be published if a flush happened right now.

  Non-destructive: nothing is drained, so the next real flush still reports these
  measurements. Useful for checking what is being collected while
  `:cloudwatch_publisher` is `nil`.
  """
  @spec preview() :: [map()]
  def preview do
    build_metric_data(read_counters(), read_gauges(), timestamp())
  end

  @doc """
  The most recent flushed batch, whether or not it was actually published.

  Returns `nil` before the first flush. `:published` distinguishes a batch that went to
  CloudWatch from one that was only built — the latter is what you get with
  `:cloudwatch_publisher` set to `nil`.
  """
  @spec last_report() ::
          %{
            required(:flushed_at) => DateTime.t(),
            required(:published) => boolean(),
            required(:metric_data) => [map()]
          }
          | nil
  def last_report(server \\ __MODULE__) do
    GenServer.call(server, :last_report)
  end

  @doc """
  Flush immediately instead of waiting for the next cycle, and return the batch.

  The timer is left alone, so this does not shift the flush cycle.
  """
  @spec flush() :: %{
          required(:flushed_at) => DateTime.t(),
          required(:published) => boolean(),
          required(:metric_data) => [map()]
        }
  def flush(server \\ __MODULE__) do
    GenServer.call(server, :flush, 30_000)
  end

  @doc "Discard everything accumulated so far without publishing it."
  @spec reset() :: :ok
  def reset do
    :ets.delete_all_objects(@counters)
    :ets.delete_all_objects(@gauges)
    :ok
  rescue
    ArgumentError -> :ok
  end

  @impl GenServer
  def init(_opts) do
    Process.flag(:trap_exit, true)

    table_opts = [:public, :named_table, :set, write_concurrency: true, read_concurrency: true]
    :ets.new(@counters, table_opts)
    :ets.new(@gauges, table_opts)

    state = %{last_report: nil, timer: nil}

    {:ok, schedule_flush(state)}
  end

  @impl GenServer
  def handle_call(:last_report, _from, state), do: {:reply, state.last_report, state}

  def handle_call(:flush, _from, state) do
    state = do_flush(state)
    {:reply, state.last_report, state}
  end

  @impl GenServer
  def handle_info(:flush, state) do
    {:noreply, state |> do_flush() |> schedule_flush()}
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_reason, state) do
    # Best effort, so a rolling deploy does not drop the last minute of measurements.
    do_flush(state)
    :ok
  end

  @doc """
  Returns the current metrics publisher.
  """
  def publisher,
    do: Application.get_env(:meadow, :metrics, [])[:publisher]

  @doc """
  Sets the current metrics publisher.
  """
  def set_publisher(value) do
    Application.put_env(:meadow, :metrics, Keyword.put(Application.get_env(:meadow, :metrics, []), :publisher, value))
  end

  defp schedule_flush(state) do
    # Align to the minute boundary: CloudWatch's standard resolution is one minute, so
    # the period a datapoint lands in is all that matters.
    delay = @flush_interval - rem(System.os_time(:millisecond), @flush_interval)
    %{state | timer: Process.send_after(self(), :flush, delay)}
  end

  defp do_flush(state) do
    run_probes()

    report = %{
      flushed_at: DateTime.utc_now(),
      published: false,
      metric_data: build_metric_data(drain_counters(), read_gauges(), timestamp())
    }

    %{state | last_report: publish(report)}
  end

  # Read at flush time rather than captured at startup, so a test can empty the list
  # without restarting the aggregator.
  defp probes,
    do: Application.get_env(:meadow, :metrics_probes, [&Meadow.Metrics.Probes.run/0])

  defp run_probes do
    Enum.each(probes(), fn probe ->
      try do
        probe.()
      rescue
        exception ->
          Logger.warning("Telemetry probe failed: #{Exception.message(exception)}")
      end
    end)
  end

  defp publish(%{metric_data: []} = report), do: report

  defp publish(%{metric_data: _} = report) do
    publish(report, publisher())
  end

  defp publish(report, nil), do: report

  defp publish(%{metric_data: metric_data} = report, publisher) do
    case publisher.put_metric_data(metric_data, @chunk_size) do
      :ok ->
        %{report | published: true}

      {:error, reason} ->
        Logger.warning("Unable to publish #{length(metric_data)} metrics: #{inspect(reason)}")
        report
    end
  end

  # Reading and draining

  defp read_counters do
    :ets.tab2list(@counters)
  rescue
    ArgumentError -> []
  end

  # Read every counter, then subtract exactly what was read. An increment landing between
  # the read and the subtraction survives into the next flush rather than being lost, which
  # is why this does not simply delete the rows. Rows are left in place at zero; the key
  # space is bounded by metric cardinality, which is small by design.
  defp drain_counters do
    rows = read_counters()

    Enum.each(rows, fn {key, value} ->
      :ets.update_counter(@counters, key, {2, -value})
    end)

    rows
  end

  defp read_gauges do
    :ets.tab2list(@gauges)
  rescue
    ArgumentError -> []
  end

  defp increment(key, n) do
    :ets.update_counter(@counters, key, {2, n}, {key, 0})
    :ok
  rescue
    # The table only exists while the aggregator is running. Measurements emitted outside
    # its lifetime are dropped rather than crashing the process that emitted them.
    ArgumentError -> :ok
  end

  # Building CloudWatch metric data

  defp build_metric_data(counters, gauges, timestamp) do
    {histogram_rows, counter_rows} =
      counters
      |> Enum.reject(fn {_key, value} -> value == 0 end)
      |> Enum.split_with(fn {key, _value} -> elem(key, 0) == :hist end)

    histogram_data(histogram_rows, timestamp) ++
      counter_data(counter_rows, timestamp) ++
      gauge_data(gauges, timestamp)
  end

  defp histogram_data(rows, timestamp) do
    rows
    |> Enum.group_by(
      fn {{:hist, name, dimensions, _index}, _count} -> {name, dimensions} end,
      fn {{:hist, _name, _dimensions, index}, count} -> {Histogram.bound(index), count} end
    )
    |> Enum.map(fn {{name, dimensions}, buckets} ->
      {values, counts} = buckets |> Enum.sort() |> Enum.unzip()

      datum(name, dimensions, timestamp, "Milliseconds")
      |> Map.merge(%{"Values" => values, "Counts" => counts})
    end)
  end

  defp counter_data(rows, timestamp) do
    Enum.map(rows, fn {{:count, name, dimensions}, value} ->
      datum(name, dimensions, timestamp, "Count")
      |> Map.put("Value", value)
    end)
  end

  defp gauge_data(rows, timestamp) do
    Enum.map(rows, fn {{name, dimensions}, value, unit} ->
      datum(name, dimensions, timestamp, unit)
      |> Map.put("Value", value)
    end)
  end

  defp datum(name, dimensions, timestamp, unit) do
    %{
      "MetricName" => name,
      "Dimensions" => Enum.map(dimensions, fn {k, v} -> %{"Name" => k, "Value" => v} end),
      "Timestamp" => timestamp,
      "Unit" => unit
    }
  end

  # Epoch seconds floored to the minute, so every node publishing in the same minute lands
  # in the same CloudWatch period and gets merged.
  defp timestamp do
    seconds = System.os_time(:second)
    seconds - rem(seconds, 60)
  end

  # Dimension order has to be stable or the same logical metric would accumulate under
  # several ETS keys and publish as several CloudWatch metrics.
  defp normalize_dimensions(dimensions) do
    dimensions
    |> Enum.map(fn {name, value} -> {to_string(name), to_string(value)} end)
    |> Enum.sort()
  end
end
