defmodule Meadow.MetricsTest do
  use ExUnit.Case, async: false

  alias Meadow.Metrics
  alias Meadow.Pipeline.Actions.{CreateTranscodeJob, FileSetComplete}
  alias TelemetryMetricsCloudwatch.Cache

  setup do
    previous_env = Application.get_env(:meadow, :environment)
    previous_metrics = Application.get_env(:meadow, :metrics, [])

    on_exit(fn ->
      Application.put_env(:meadow, :metrics, previous_metrics)
      Application.delete_env(:meadow, :cloudwatch_namespace)
      Application.delete_env(:meadow, :cloudwatch_deployed_tenants)
      Application.delete_env(:meadow, :environment_prefix)

      case previous_env do
        nil -> Application.delete_env(:meadow, :environment)
        env -> Application.put_env(:meadow, :environment, env)
      end
    end)

    :ok
  end

  defp tenant(value), do: Application.put_env(:meadow, :environment_prefix, value)

  describe "namespace/0" do
    test "staging and production share a namespace, being in separate accounts" do
      tenant("meadow")
      assert Metrics.namespace() == "Meadow"

      tenant("staging")
      assert Metrics.namespace() == "Meadow"
    end

    test "a dev box does not collide with staging, which shares its account" do
      tenant("staging")
      staging = Metrics.namespace()

      tenant("mbk")
      assert Metrics.namespace() == "Meadow/mbk"
      refute Metrics.namespace() == staging
    end

    test "an unset tenant falls back to the bare namespace" do
      Application.delete_env(:meadow, :environment_prefix)
      assert Metrics.namespace() == "Meadow"

      tenant("")
      assert Metrics.namespace() == "Meadow"
    end

    test "the tenants sharing the base namespace are configurable" do
      Application.put_env(:meadow, :cloudwatch_deployed_tenants, ~w(meadow staging demo))
      tenant("demo")

      assert Metrics.namespace() == "Meadow"
    end

    test "an explicit namespace wins over the tenant" do
      tenant("staging")
      Application.put_env(:meadow, :cloudwatch_namespace, "Meadow/custom")

      assert Metrics.namespace() == "Meadow/custom"
    end
  end

  describe "enabled?/0" do
    test "is off in test, where a minute-long push cycle is only noise" do
      Application.put_env(:meadow, :environment, :test)
      Application.put_env(:meadow, :metrics, [])

      refute Metrics.enabled?()
    end

    test "is on elsewhere by default" do
      Application.put_env(:meadow, :environment, :dev)
      Application.put_env(:meadow, :metrics, [])

      assert Metrics.enabled?()
    end

    test "can be forced either way" do
      Application.put_env(:meadow, :environment, :test)
      Application.put_env(:meadow, :metrics, enabled: true)
      assert Metrics.enabled?()

      Application.put_env(:meadow, :environment, :dev)
      Application.put_env(:meadow, :metrics, enabled: false)
      refute Metrics.enabled?()
    end
  end

  describe "reporter_options/0" do
    test "runs dry outside production" do
      Application.put_env(:meadow, :environment, :dev)
      System.delete_env("MEADOW_CLOUDWATCH_CONFIRM")

      assert Keyword.fetch!(Metrics.reporter_options(), :dry_run)
    end

    test "publishes for real in production" do
      Application.put_env(:meadow, :environment, :prod)

      refute Keyword.fetch!(Metrics.reporter_options(), :dry_run)
    end

    test "names the reporter so its state can be inspected" do
      Application.put_env(:meadow, :environment, :dev)

      assert Keyword.fetch!(Metrics.reporter_options(), :name) == Metrics.reporter()
    end
  end

  describe "metric definitions" do
    test "are all types the reporter supports" do
      # validate_metrics/1 only warns, so the assertion is on the absence of a warning.
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          Cache.validate_metrics(Meadow.Telemetry.cloudwatch_metrics())
        end)

      refute log =~ "not supported by the Reporter"
    end

    test "every metric extracts a number from the event it listens to" do
      # The reporter silently drops an event whose measurement comes back nil, so a
      # metric left to default its measurement would never fire on an event that has no
      # matching key. Declaring a unit turns the measurement into a conversion function,
      # so the only way to check this is to run it against what the event really carries.
      carried = %{
        [:meadow, :pipeline, :action, :stop] => %{duration: 1_000_000, monotonic_time: 1},
        [:meadow, :pipeline, :action, :skip] => %{count: 1},
        [:meadow, :pipeline, :action, :exception] => %{duration: 1_000_000, monotonic_time: 1},
        [:meadow, :pipeline, :transcode, :complete] => %{duration_ms: 500},
        [:meadow, :pipeline, :file_set, :complete] => %{duration_ms: 500},
        [:meadow, :pipeline, :transcode, :stalled] => %{count: 1}
      }

      for metric <- Meadow.Telemetry.cloudwatch_metrics() do
        measurements = Map.fetch!(carried, metric.event_name)

        value =
          case metric.measurement do
            fun when is_function(fun, 1) -> fun.(measurements)
            key -> measurements[key]
          end

        assert is_number(value),
               "#{Enum.join(metric.name, ".")} extracted #{inspect(value)} from " <>
                 "#{inspect(metric.event_name)} measurements #{inspect(measurements)}"
      end
    end
  end

  describe "publish_action?/1" do
    test "keeps an action on the allowlist" do
      Application.put_env(:meadow, :metrics, actions: ~w(CreateTranscodeJob))

      assert Meadow.Telemetry.publish_action?(%{action: CreateTranscodeJob})
    end

    test "drops an action that is not" do
      Application.put_env(:meadow, :metrics, actions: ~w(CreateTranscodeJob))

      refute Meadow.Telemetry.publish_action?(%{action: FileSetComplete})
    end

    test "drops metadata with no action at all" do
      Application.put_env(:meadow, :metrics, actions: ~w(CreateTranscodeJob))

      refute Meadow.Telemetry.publish_action?(%{})
    end

    test "accepts an action already reduced to a string" do
      Application.put_env(:meadow, :metrics, actions: ~w(CreateTranscodeJob))

      assert Meadow.Telemetry.publish_action?(%{action: "CreateTranscodeJob"})
    end
  end

  describe "with the reporter actually running" do
    setup do
      Application.put_env(:meadow, :environment, :dev)
      Application.put_env(:meadow, :metrics, actions: ~w(ExtractMimeType))
      System.delete_env("MEADOW_CLOUDWATCH_CONFIRM")
      tenant("mbk")

      # Started directly rather than through Meadow.Metrics, so the test owns its
      # lifetime. dry_run keeps it from reaching AWS even if something is misconfigured.
      {:ok, pid} =
        start_supervised(
          {TelemetryMetricsCloudwatch,
           Keyword.merge(Metrics.reporter_options(), dry_run: true, push_interval: 60_000)}
        )

      {:ok, reporter: pid}
    end

    defp pending_names do
      Metrics.pending()
      |> Enum.map(&Keyword.fetch!(&1, :metric_name))
    end

    defp pending_for(name) do
      Metrics.pending()
      |> Enum.find(&(Keyword.fetch!(&1, :metric_name) == name))
    end

    test "an allowlisted action lands in the cache as a summary and a count" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: System.convert_time_unit(250, :millisecond, :native), monotonic_time: 1},
        %{action: ExtractMimeType, outcome: "ok"}
      )

      names = pending_names()
      assert "pipeline.action.duration.summary" in names
      assert "pipeline.action.count.count" in names

      datum = pending_for("pipeline.action.duration.summary")
      assert Keyword.fetch!(datum, :unit) == "Milliseconds"
      assert [value] = Keyword.fetch!(datum, :values)
      assert_in_delta value, 250, 1

      assert Keyword.fetch!(datum, :dimensions) == [action: "ExtractMimeType"]
    end

    test "an action off the allowlist is dropped before it reaches the cache" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: 1_000, monotonic_time: 1},
        %{action: FileSetComplete, outcome: "ok"}
      )

      assert Metrics.pending() == []
    end

    test "a transcode duration arrives already in milliseconds" do
      :telemetry.execute(
        [:meadow, :pipeline, :transcode, :complete],
        %{duration_ms: 90_000},
        %{media_type: "video", outcome: "ok"}
      )

      datum = pending_for("pipeline.transcode.duration.summary")
      assert Keyword.fetch!(datum, :values) == [90_000]
      assert Keyword.fetch!(datum, :dimensions) == [media_type: "video"]
    end

    test "a sampled probe arrives as a last_value" do
      :telemetry.execute([:meadow, :pipeline, :transcode, :stalled], %{count: 3}, %{})

      datum = pending_for("pipeline.transcode.stalled.last_value")
      assert Keyword.fetch!(datum, :value) == 3
    end

    test "pending/0 does not drain what it reports" do
      :telemetry.execute(
        [:meadow, :pipeline, :transcode, :complete],
        %{duration_ms: 1_000},
        %{media_type: "audio", outcome: "ok"}
      )

      assert pending_for("pipeline.transcode.duration.summary")
      assert pending_for("pipeline.transcode.duration.summary")
    end

    test "pending/0 is empty when the reporter is not running" do
      stop_supervised(TelemetryMetricsCloudwatch)
      assert Metrics.pending() == []
    end
  end
end
