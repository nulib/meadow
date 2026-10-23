defmodule Meadow.Telemetry do
  @moduledoc """
  The `:telemetry` side of Meadow's instrumentation.

  Attaches the handlers that transform events, and owns every metric definition. Two
  consumers read those definitions and neither keeps anything of its own:

    * `metrics/0` -- Live Dashboard, which samples live and stores nothing.
    * `cloudwatch_metrics/0` -- `Meadow.Metrics`, which hands them to
      `TelemetryMetricsCloudwatch` to aggregate and push once a minute.

  The CloudWatch list is deliberately a subset. VM, Ecto, Phoenix and Absinthe metrics
  are there for the dashboard only: they are either already covered by an AWS namespace
  or, in Absinthe's case, would mint a metric per GraphQL root field.
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

  @doc """
  Every metric Live Dashboard displays.
  """
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

      # Absinthe Operation Metrics (Live Dashboard only)
      summary("meadow.graphql.operation.time.duration",
        tags: [:type, :field],
        unit: {:native, :millisecond}
      )
    ] ++ pipeline_metrics()
  end

  @doc """
  The metrics `Meadow.Metrics` publishes to CloudWatch.

  `TelemetryMetricsCloudwatch` suffixes each CloudWatch metric name by type, so these
  arrive as `pipeline.action.duration.summary`, `pipeline.action.count.count` and so on.
  The names are given explicitly rather than derived from the event path, so the suffix
  lands on something readable.
  """
  def cloudwatch_metrics, do: pipeline_metrics()

  # Shared by both consumers. Durations from the action span are in native units;
  # the cross-action measurements are wall clock differences already in milliseconds,
  # which is why they are named duration_ms.
  defp pipeline_metrics do
    [
      summary("pipeline.action.duration",
        event_name: [:meadow, :pipeline, :action, :stop],
        measurement: :duration,
        keep: &publish_action?/1,
        tag_values: &short_action/1,
        tags: [:action],
        unit: {:native, :millisecond}
      ),
      # Every counter names a measurement that the event actually carries. The reporter
      # drops an event whose measurement key is missing, and a counter's measurement
      # would otherwise default to the last segment of its name -- :count, which none of
      # these events has. The value is ignored; only its presence matters.
      counter("pipeline.action.count",
        event_name: [:meadow, :pipeline, :action, :stop],
        measurement: :duration,
        keep: &publish_action?/1,
        tag_values: &short_action/1,
        tags: [:action, :outcome]
      ),
      counter("pipeline.action.count",
        event_name: [:meadow, :pipeline, :action, :skip],
        measurement: :count,
        keep: &publish_action?/1,
        tag_values: &skipped_action/1,
        tags: [:action, :outcome]
      ),
      counter("pipeline.action.exception",
        event_name: [:meadow, :pipeline, :action, :exception],
        measurement: :duration,
        keep: &publish_action?/1,
        tag_values: &short_action/1,
        tags: [:action, :kind]
      ),
      summary("pipeline.transcode.duration",
        event_name: [:meadow, :pipeline, :transcode, :complete],
        measurement: :duration_ms,
        tags: [:media_type],
        unit: :millisecond
      ),
      counter("pipeline.transcode.count",
        event_name: [:meadow, :pipeline, :transcode, :complete],
        measurement: :duration_ms,
        tags: [:media_type, :outcome]
      ),
      summary("pipeline.file_set.duration",
        event_name: [:meadow, :pipeline, :file_set, :complete],
        measurement: :duration_ms,
        tags: [:role, :media_type],
        unit: :millisecond
      ),
      last_value("pipeline.transcode.stalled",
        event_name: [:meadow, :pipeline, :transcode, :stalled],
        measurement: :count
      )
    ]
  end

  @doc """
  Whether an action's timings should be reported.

  Used as the `:keep` predicate on the action metrics, so an action off the list is
  dropped before it reaches either consumer. The dispatch and completion bookkeeping
  actions are left off because their timings are noise next to the actions doing real
  work; `pipeline.file_set.duration` is a separate event and is unaffected.
  """
  def publish_action?(metadata) do
    case action_name(metadata) do
      nil ->
        false

      action ->
        Application.get_env(:meadow, :metrics, [])
        |> Keyword.get(:actions, [])
        |> Enum.member?(action)
    end
  end

  def by_action(metadata) do
    with action <- metadata.name |> to_string() |> String.split(".") |> Enum.at(4) do
      Map.put(metadata, :action, action)
    end
  end

  @doc """
  Reduce an action module to its last segment, for use as a tag value.

  The span carries the module itself so handlers can pattern match on it; a full module
  name makes for an unreadable dimension.
  """
  def short_action(metadata) do
    case action_name(metadata) do
      nil -> metadata
      action -> Map.put(metadata, :action, action)
    end
  end

  @doc """
  Tag values for the skip event, which has no outcome of its own.

  Skips share `pipeline.action.count` with the stop event so the outcomes of an action
  are one metric rather than two.
  """
  def skipped_action(metadata) do
    metadata
    |> short_action()
    |> Map.put(:outcome, "skip")
  end

  defp action_name(%{action: action}) when is_atom(action) and not is_nil(action),
    do: action |> Module.split() |> List.last()

  defp action_name(%{action: action}) when is_binary(action), do: action
  defp action_name(_), do: nil

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
