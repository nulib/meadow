defmodule Meadow.Telemetry.HandlersTest do
  @moduledoc """
  Exercises the translation from pipeline telemetry events to aggregator measurements.

  The handlers are attached by `Meadow.Telemetry` at application start, so these tests
  emit real events and read back what landed in the aggregator.
  """
  use Meadow.DataCase, shared: true

  import ExUnit.CaptureLog

  alias Meadow.Pipeline.Actions.{ExtractMimeType, FileSetComplete}
  alias Meadow.Metrics.Aggregator
  alias Meadow.Telemetry.Handlers

  @allowed ~w(ExtractMimeType FileSetComplete)

  setup do
    Aggregator.reset()

    previous = Application.get_env(:meadow, :metrics, [])
    Application.put_env(:meadow, :metrics, Keyword.put(previous, :actions, @allowed))

    on_exit(fn ->
      Aggregator.reset()
      Application.put_env(:meadow, :metrics, previous)
    end)

    :ok
  end

  defp allow(actions) do
    metrics = Application.get_env(:meadow, :metrics, [])
    Application.put_env(:meadow, :metrics, Keyword.put(metrics, :actions, actions))
  end

  defp native(milliseconds),
    do: System.convert_time_unit(milliseconds, :millisecond, :native)

  defp find(name), do: Enum.find(Aggregator.preview(), &(&1["MetricName"] == name))

  defp dimensions(datum),
    do: Enum.into(datum["Dimensions"], %{}, &{&1["Name"], &1["Value"]})

  describe "action stop" do
    test "records duration and count under the action's short name" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(250)},
        %{action: ExtractMimeType, outcome: "ok"}
      )

      duration = find("pipeline.action.duration")
      assert dimensions(duration) == %{"Action" => "ExtractMimeType"}
      assert duration["Unit"] == "Milliseconds"
      assert Enum.sum(duration["Counts"]) == 1

      count = find("pipeline.action.count")
      assert dimensions(count) == %{"Action" => "ExtractMimeType", "Outcome" => "ok"}
      assert count["Value"] == 1
    end

    test "converts the span's native duration to milliseconds" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(1_000)},
        %{action: ExtractMimeType, outcome: "ok"}
      )

      # Bucket bounds overstate by at most √2, so a one second measurement must land in a
      # bucket between 1000ms and 1415ms -- not in the single-digit milliseconds it would
      # reach if native units were published unconverted.
      assert [bound] = find("pipeline.action.duration")["Values"]
      assert bound >= 1_000 and bound <= 1_415
    end

    test "separates outcomes on the counter" do
      for outcome <- ["ok", "ok", "error"] do
        :telemetry.execute(
          [:meadow, :pipeline, :action, :stop],
          %{duration: native(5)},
          %{action: ExtractMimeType, outcome: outcome}
        )
      end

      by_outcome =
        Aggregator.preview()
        |> Enum.filter(&(&1["MetricName"] == "pipeline.action.count"))
        |> Enum.into(%{}, &{dimensions(&1)["Outcome"], &1["Value"]})

      assert by_outcome == %{"ok" => 2, "error" => 1}
    end
  end

  describe "action skip" do
    test "is counted but not timed" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :skip],
        %{count: 1},
        %{action: ExtractMimeType}
      )

      assert dimensions(find("pipeline.action.count")) == %{
               "Action" => "ExtractMimeType",
               "Outcome" => "skip"
             }

      refute find("pipeline.action.duration")
    end
  end

  describe "action exception" do
    test "is counted separately from outcomes" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :exception],
        %{duration: native(5)},
        %{action: ExtractMimeType, kind: :error}
      )

      assert dimensions(find("pipeline.action.exception")) == %{
               "Action" => "ExtractMimeType",
               "Kind" => "error"
             }
    end
  end

  describe "transcode complete" do
    test "records duration already in milliseconds" do
      :telemetry.execute(
        [:meadow, :pipeline, :transcode, :complete],
        %{duration_ms: 90_000},
        %{media_type: "video", outcome: "ok"}
      )

      datum = find("pipeline.transcode.duration")
      assert dimensions(datum) == %{"MediaType" => "video"}
      assert [bound] = datum["Values"]
      assert bound >= 90_000 and bound <= 127_280
    end
  end

  describe "robustness" do
    test "an event missing its metadata is ignored without raising" do
      # No action in the metadata resolves to "unknown", which is never on the allowlist,
      # so this returns before touching measurements rather than being rescued.
      log =
        capture_log(fn ->
          assert :telemetry.execute([:meadow, :pipeline, :action, :stop], %{}, %{}) == :ok
        end)

      refute log =~ "Telemetry handler"
      assert Aggregator.preview() == []

      assert_still_recording()
    end

    test "an allowlisted event with malformed measurements is rescued" do
      # This one does reach the measurement read, so the rescue is what keeps :telemetry
      # from detaching the handler permanently.
      log =
        capture_log(fn ->
          :telemetry.execute([:meadow, :pipeline, :action, :stop], %{}, %{
            action: ExtractMimeType,
            outcome: "ok"
          })
        end)

      assert log =~ "Telemetry handler for action_stop failed"

      assert_still_recording()
    end

    # :telemetry detaches a handler that raises, so every robustness case has to prove
    # the next well-formed event still lands.
    defp assert_still_recording do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(5)},
        %{action: ExtractMimeType, outcome: "ok"}
      )

      assert find("pipeline.action.count")["Value"] == 1
    end

    test "unknown events are ignored" do
      assert Handlers.handle_event([:something, :else], %{}, %{}, nil) == :ok
    end
  end

  describe "action selectivity" do
    test "an action on the allowlist is timed and counted" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(5)},
        %{action: ExtractMimeType, outcome: "ok"}
      )

      assert find("pipeline.action.duration")
      assert find("pipeline.action.count")["Value"] == 1
    end

    test "an action off the allowlist is neither timed nor counted" do
      allow(~w(SomethingElse))

      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(5)},
        %{action: ExtractMimeType, outcome: "ok"}
      )

      refute find("pipeline.action.duration")
      refute find("pipeline.action.count")
    end

    test "skips and exceptions respect the allowlist too" do
      allow(~w(SomethingElse))

      :telemetry.execute([:meadow, :pipeline, :action, :skip], %{count: 1}, %{
        action: ExtractMimeType
      })

      :telemetry.execute([:meadow, :pipeline, :action, :exception], %{duration: native(5)}, %{
        action: ExtractMimeType,
        kind: :error
      })

      refute find("pipeline.action.count")
      refute find("pipeline.action.exception")
    end

    test "end-to-end file set duration is published whatever the allowlist says" do
      # FileSetComplete is not on the production allowlist, but the metric measured from
      # kickoff has to survive that or it would never be emitted at all.
      allow(~w(SomethingElse))

      :telemetry.execute(
        [:meadow, :pipeline, :file_set, :complete],
        %{duration_ms: 1_000},
        %{role: "A", media_type: "image"}
      )

      assert find("pipeline.file_set.duration")
    end
  end

  describe "media_type/1" do
    test "buckets mime types by top-level type" do
      assert Handlers.media_type("audio/mpeg") == "audio"
      assert Handlers.media_type("video/mp4") == "video"
      assert Handlers.media_type("image/tiff") == "image"
      assert Handlers.media_type("application/pdf") == "other"
      assert Handlers.media_type(nil) == "other"
    end

    test "is idempotent, because emitters classify before the handler sees the value" do
      for mime <- ["audio/mpeg", "video/mp4", "image/tiff", "application/pdf", nil] do
        once = Handlers.media_type(mime)
        assert Handlers.media_type(once) == once
      end
    end
  end

  describe "file set completion" do
    test "a stop event for a non-terminal action emits no end-to-end measurement" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(5)},
        %{action: ExtractMimeType, outcome: "ok", file_set_id: Ecto.UUID.generate()}
      )

      refute find("pipeline.file_set.duration")
    end

    test "FileSetComplete without action states emits no end-to-end measurement" do
      :telemetry.execute(
        [:meadow, :pipeline, :action, :stop],
        %{duration: native(5)},
        %{action: FileSetComplete, outcome: "ok", file_set_id: Ecto.UUID.generate()}
      )

      refute find("pipeline.file_set.duration")
    end
  end
end
