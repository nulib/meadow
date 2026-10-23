defmodule Meadow.Metrics do
  @moduledoc """
  Delivery of Meadow's metrics to CloudWatch.

  The aggregation and publishing are `TelemetryMetricsCloudwatch`'s job: it attaches to
  the events named in `Meadow.Telemetry.cloudwatch_metrics/0`, accumulates them in
  process state and pushes to CloudWatch at least once a minute. What is left here is
  the Meadow-specific part -- which namespace to publish under, and whether a given node
  is allowed to publish at all.

  ## Namespaces

  Staging and production are in separate AWS accounts and deliberately share the bare
  `"Meadow"` namespace, which keeps a dashboard or alarm portable between them. Every
  other tenant gets its own, because developer environments share an account with
  staging and would otherwise land on staging's own metric names:

      production (MEADOW_TENANT=meadow)  -> "Meadow"
      staging    (MEADOW_TENANT=staging) -> "Meadow"       # separate account
      a dev box  (MEADOW_TENANT=mbk)     -> "Meadow/mbk"

  The task role allows `cloudwatch:PutMetricData` only for the bare namespace.
  `PutMetricData` takes no resource-level permissions, so the `cloudwatch:namespace`
  condition key is what scopes it.

  ## Dry runs

  Outside production the reporter starts in dry-run mode unless
  `Meadow.Metrics.Confirmation` says otherwise, which logs each batch instead of sending
  it. That is the local inspection path: real aggregation, real metric data, no AWS
  round trip and nothing billable.
  """

  use Supervisor

  alias Meadow.Metrics.Confirmation
  alias TelemetryMetricsCloudwatch.Cache

  require Logger

  @reporter Meadow.Metrics.Reporter
  @base_namespace "Meadow"
  @deployed_tenants ~w(meadow staging)
  @default_push_interval :timer.minutes(1)

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  defp children do
    if enabled?() do
      [
        {TelemetryMetricsCloudwatch, reporter_options()},
        # Probes measure the absence of an event, which no event can report, so they are
        # sampled on a timer and emitted as events of their own.
        {:telemetry_poller,
         measurements: [{Meadow.Metrics.Probes, :run, []}],
         period: push_interval(),
         name: :meadow_metrics_poller}
      ]
    else
      []
    end
  end

  @doc """
  The options the reporter is started with.

  Exposed so it can be inspected without starting anything.
  """
  def reporter_options do
    live = Confirmation.live?()
    log_mode(live, Confirmation.reason())

    [
      name: @reporter,
      metrics: Meadow.Telemetry.cloudwatch_metrics(),
      namespace: namespace(),
      push_interval: push_interval(),
      dry_run: not live
    ]
  end

  defp log_mode(true, reason),
    do: Logger.warning("Publishing live CloudWatch metrics to #{namespace()} (#{reason})")

  defp log_mode(false, reason) do
    Logger.info(
      "Metrics reporter starting in dry-run mode (#{reason}); batches will be logged " <>
        "rather than sent to CloudWatch"
    )
  end

  @doc """
  Whether the reporter runs on this node at all.

  Off in `:test`, where a minute-long push cycle would only add noise, and configurable
  with `metrics[:enabled]` elsewhere.
  """
  def enabled? do
    case Application.get_env(:meadow, :metrics, []) |> Keyword.get(:enabled) do
      nil -> Meadow.Config.environment() != :test
      value -> value
    end
  end

  @doc "The CloudWatch namespace metrics are published under."
  def namespace do
    Application.get_env(:meadow, :cloudwatch_namespace) || namespace_for(tenant())
  end

  @doc """
  The metric data the next push would send, without sending or draining it.

  Reads the reporter's accumulated state and runs the same transformation the push does.
  `Cache.pop_metrics/1` is pure -- it returns a new cache rather than mutating the
  running one -- so this is a genuine preview rather than a destructive read.

  Returns `[]` when the reporter is not running.
  """
  def pending do
    case Process.whereis(@reporter) do
      nil ->
        []

      pid ->
        pid
        |> :sys.get_state()
        |> Cache.pop_metrics()
        |> elem(1)
    end
  end

  @doc "Push now rather than waiting for the next cycle."
  def flush do
    case Process.whereis(@reporter) do
      nil -> :ok
      pid -> send(pid, :push_check) && :ok
    end
  end

  @doc "The process name the reporter is registered under."
  def reporter, do: @reporter

  defp push_interval do
    Application.get_env(:meadow, :metrics, [])
    |> Keyword.get(:push_interval, @default_push_interval)
  end

  defp namespace_for(tenant) when tenant in [nil, ""], do: @base_namespace

  defp namespace_for(tenant) do
    if tenant in deployed_tenants(),
      do: @base_namespace,
      else: "#{@base_namespace}/#{tenant}"
  end

  defp deployed_tenants,
    do: Application.get_env(:meadow, :cloudwatch_deployed_tenants, @deployed_tenants)

  defp tenant, do: Application.get_env(:meadow, :environment_prefix)
end
