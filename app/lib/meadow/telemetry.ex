defmodule Meadow.Telemetry do
  @moduledoc """
  Define metrics panels for Live Dashboard
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
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
      )
    ]
  end

  def by_action(metadata) do
    with action <- metadata.name |> to_string() |> String.split(".") |> Enum.at(4) do
      Map.put(metadata, :action, action)
    end
  end
end
