defmodule Meadow.Telemetry do
  @moduledoc """
  The `:telemetry` side of Meadow's instrumentation.

  Attaches the pipeline handlers and describes the events for Live Dashboard. Nothing
  here knows about CloudWatch; the aggregation and delivery of metrics lives in
  `Meadow.Metrics`, which `Meadow.Telemetry.Handlers` feeds.

  Two consumers hang off the same events. `metrics/0` describes them for Live Dashboard,
  which samples them live and keeps nothing. `Meadow.Telemetry.Handlers` records a subset
  of them on `Meadow.Metrics.Aggregator`, which flushes aggregates once a minute.

  Absinthe metrics are defined here for Live Dashboard only; see
  `Meadow.Telemetry.Handlers` for why they are kept out of CloudWatch.
  """

  use Supervisor
  import Telemetry.Metrics

  alias Meadow.Telemetry.Handlers

  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Handlers.attach()

    # No children: this supervisor exists to own the handler attachment, which is a
    # global side effect that should be undone and redone if the tree restarts.
    Supervisor.init([], strategy: :one_for_one)
  end

  def metrics do
    [
      # Erlang VM Metrics - Formats `gauge` metric type
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.system_counts.process_count"),

      # Database Time Metrics - Formats `timing` metric type
      summary(
        "meadow.repo.query.total_time",
        unit: {:native, :millisecond},
        tags: [:source, :command]
      ),

      # Database Count Metrics - Formats `count` metric type
      counter(
        "meadow.repo.query.count",
        tags: [:source, :command]
      ),

      # Phoenix Time Metrics - Formats `timing` metric type
      summary(
        "phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond}
      ),

      # Phoenix Count Metrics - Formats `count` metric type
      counter("phoenix.router_dispatch.stop.count"),
      counter("phoenix.error_rendered.count"),
      counter("broadway.processor.message.start.time", tag_values: &by_action/1, tags: [:action]),
      summary("broadway.processor.message.stop.duration",
        tag_values: &by_action/1,
        tags: [:action]
      ),
      counter("broadway.processor.message.exception.time",
        tag_values: &by_action/1,
        tags: [:action]
      ),

      # Meadow Pipeline - the span around each action's own process/2
      summary("meadow.pipeline.action.stop.duration",
        tag_values: &short_action/1,
        tags: [:action, :outcome],
        unit: {:native, :millisecond}
      ),
      counter("meadow.pipeline.action.stop.count",
        tag_values: &short_action/1,
        tags: [:action, :outcome]
      ),
      counter("meadow.pipeline.action.skip.count", tag_values: &short_action/1, tags: [:action]),
      counter("meadow.pipeline.action.exception.count",
        tag_values: &short_action/1,
        tags: [:action, :kind]
      ),

      # Meadow Pipeline - measurements spanning more than one action, in milliseconds
      # rather than native units because they are wall clock differences
      summary("meadow.pipeline.transcode.complete.duration_ms",
        tags: [:media_type, :outcome],
        unit: :millisecond
      ),
      summary("meadow.pipeline.file_set.complete.duration_ms",
        tags: [:role, :media_type],
        unit: :millisecond
      ),

      # Absinthe Operation Metrics (Live Dashboard only)
      summary("meadow.graphql.operation.time.duration",
        tags: [:type, :field],
        unit: {:native, :millisecond}
      )
    ]
  end

  def by_action(metadata) do
    with action <- metadata.name |> to_string() |> String.split(".") |> Enum.at(4) do
      Map.put(metadata, :action, action)
    end
  end

  @doc """
  Reduce an action module to its last segment for display.

  The span carries the module itself so handlers can pattern match on it; a full module
  name makes for an unreadable dashboard tag.
  """
  def short_action(%{action: action} = metadata) when is_atom(action) and not is_nil(action),
    do: Map.put(metadata, :action, action |> Module.split() |> List.last())

  def short_action(metadata), do: metadata

  @doc """
  Log how long a file set reorder took.

  Reads the work and file set count from metadata rather than measurements: the span
  reports `:duration` as its measurement, and everything describing *what* was measured
  travels as metadata.
  """
  def handle_reorder_file_sets_stop_event(
        [:meadow, :data, :works, :reorder_file_sets, :stop],
        %{duration: duration},
        %{work_id: work_id, file_set_count: file_set_count},
        _config
      ) do
    duration_in_seconds = :erlang.convert_time_unit(duration, :native, :second)

    Logger.info(
      "reorder_file_sets operation for #{work_id} with #{file_set_count} file sets took #{duration_in_seconds} seconds (#{duration} monotonic time units)"
    )
  end
end
