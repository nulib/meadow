defmodule Meadow.Metrics do
  @moduledoc """
  Aggregated metrics and their delivery to CloudWatch.

  The split against `Meadow.Telemetry` is by what each side is about rather than by what
  it happens to touch. `Meadow.Telemetry` is the `:telemetry` side: it attaches handlers,
  re-emits events and describes them for Live Dashboard, all of which would still make
  sense if CloudWatch did not exist. Everything here exists because CloudWatch does --
  the accumulator, the bucketing that makes percentiles possible, the publishers, and the
  boot-time confirmation that keeps a dev box from publishing by accident.

  Measurements flow one way: `Meadow.Telemetry.Handlers` receives `:telemetry` events and
  records them here, so this namespace never needs to know what a telemetry event is.

  ## Reading what is being collected

      Meadow.Metrics.preview()      # what the next flush would send
      Meadow.Metrics.last_report()  # what the last flush did send, or would have
      Meadow.Metrics.flush()        # flush now instead of waiting for the cycle

  Publishing is governed by `:cloudwatch_publisher`. `nil` -- the default everywhere but
  production -- aggregates without sending anything. `Meadow.Metrics.Logger` logs what
  would be sent. `Meadow.Metrics.CloudWatch` is the real thing, and outside production it
  has to get past `Meadow.Metrics.Confirmation` first.
  """

  use Supervisor

  alias Meadow.Metrics.Aggregator

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init([Aggregator], strategy: :one_for_one)
  end

  @doc "The metric data the next flush would publish, without draining it."
  defdelegate preview(), to: Aggregator

  @doc "The most recent flushed batch, whether or not it was actually published."
  defdelegate last_report(), to: Aggregator

  @doc "Flush now rather than waiting for the next cycle."
  defdelegate flush(), to: Aggregator

  @doc "Discard everything accumulated so far without publishing it."
  defdelegate reset(), to: Aggregator

  @doc "The CloudWatch namespace metrics are published under."
  defdelegate namespace(), to: Meadow.Metrics.CloudWatch

  @doc "The current metrics publisher."
  defdelegate publisher(), to: Meadow.Metrics.Aggregator

  @doc "Set the current metrics publisher."
  defdelegate set_publisher(value), to: Meadow.Metrics.Aggregator
end
