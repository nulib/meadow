defmodule Meadow.Telemetry.HandlersTest do
  @moduledoc """
  The handlers no longer translate events into measurements -- the reporter attaches
  itself to whatever `Meadow.Telemetry` declares. What is left is the one transformation
  that has to happen before a metric can exist, and the dimension helpers.
  """
  use Meadow.DataCase, shared: true

  import ExUnit.CaptureLog

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Actions.{ExtractMimeType, FileSetComplete}
  alias Meadow.Telemetry.Handlers

  @completed [:meadow, :pipeline, :file_set, :complete]

  setup do
    owner = self()
    id = "handlers-test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      id,
      [@completed],
      fn event, measurements, metadata, _ ->
        send(owner, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(id) end)
    :ok
  end

  defp action_stop(metadata),
    do: :telemetry.execute([:meadow, :pipeline, :action, :stop], %{duration: 1_000}, metadata)

  # elapsed_since_kickoff/1 measures from the earliest action state for the file set, so
  # there has to be one for the handler to have anything to report.
  defp file_set_in_pipeline do
    %{id: file_set_id} = file_set_fixture()
    ActionStates.set_state!({FileSet, file_set_id}, FileSetComplete, "waiting")
    file_set_id
  end

  describe "end-to-end file set latency" do
    test "is emitted when a file set completes" do
      file_set_id = file_set_in_pipeline()

      action_stop(%{
        action: FileSetComplete,
        outcome: "ok",
        file_set_id: file_set_id,
        role: "A",
        media_type: "image"
      })

      assert_received {:telemetry, @completed, %{duration_ms: elapsed}, metadata}
      assert is_integer(elapsed) and elapsed >= 0
      assert metadata.role == "A"
      assert metadata.media_type == "image"
      assert metadata.file_set_id == file_set_id
    end

    test "is not emitted for any other action" do
      file_set_id = file_set_in_pipeline()

      action_stop(%{action: ExtractMimeType, outcome: "ok", file_set_id: file_set_id})

      refute_received {:telemetry, @completed, _, _}
    end

    test "is not emitted for a file set with no action states to measure from" do
      action_stop(%{action: FileSetComplete, outcome: "ok", file_set_id: Ecto.UUID.generate()})

      refute_received {:telemetry, @completed, _, _}
    end

    test "defaults the dimensions rather than emitting an empty value" do
      # CloudWatch rejects an empty dimension value, so nil has to become something.
      file_set_id = file_set_in_pipeline()

      action_stop(%{action: FileSetComplete, outcome: "ok", file_set_id: file_set_id})

      assert_received {:telemetry, @completed, _, metadata}
      assert metadata.role == "unknown"
      assert metadata.media_type == "other"
    end
  end

  describe "robustness" do
    test "a malformed event does not take the handler down" do
      # :telemetry detaches a handler that raises, so the check that matters is that a
      # well-formed event still works afterwards.
      capture_log(fn -> action_stop(%{action: FileSetComplete, file_set_id: %{bad: :shape}}) end)

      action_stop(%{
        action: FileSetComplete,
        outcome: "ok",
        file_set_id: file_set_in_pipeline()
      })

      assert_received {:telemetry, @completed, _, _}
    end

    test "an event with no metadata is ignored" do
      action_stop(%{})

      refute_received {:telemetry, @completed, _, _}
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

  describe "file_set_dimensions/1" do
    test "describes a file set without exposing unbounded values" do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{mime_type: "video/mp4", location: "s3://x/y", original_filename: "y"}
        )

      assert %{media_type: "video", role: "A", file_set_id: _} =
               Handlers.file_set_dimensions(file_set)
    end

    test "is empty for anything that is not a file set" do
      assert Handlers.file_set_dimensions(nil) == %{}
      assert Handlers.file_set_dimensions(%{id: "nope"}) == %{}
    end
  end
end
