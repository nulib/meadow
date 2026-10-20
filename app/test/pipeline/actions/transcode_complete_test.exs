defmodule Meadow.Pipeline.Actions.TranscodeCompleteTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.{CreateTranscodeJob, TranscodeComplete}

  describe "process AWS MediaConvert Event" do
    setup %{message_file: file} do
      file_set = file_set_fixture()

      message =
        Path.join("test/fixtures", file)
        |> File.read!()
        |> String.replace(~r/PRESERVATION_BUCKET/, @preservation_bucket)
        |> String.replace(~r/STREAMING_BUCKET/, @streaming_bucket)
        |> Jason.decode!(keys: :atoms)
        |> AtomicMap.convert(safe: false)
        |> put_in([:detail, :user_metadata, :file_set_id], file_set.id)

      {:ok, %{file_set: file_set, message: message}}
    end

    @tag message_file: "transcode/error.json"
    test "error", %{file_set: file_set, message: message} do
      assert {:error, _, %{context: "Test", error: error}} =
               send_test_message(TranscodeComplete, message, %{})

      assert error |> String.contains?("Failed to read data")

      with state <- ActionStates.get_latest_state(file_set.id, TranscodeComplete) do
        assert state.outcome == "error"
        assert state.notes |> String.contains?("Failed to read data")
      end
    end

    @tag message_file: "transcode/complete.json"
    test "complete", %{file_set: file_set, message: message} do
      assert {:ok, _, %{context: "Test"}} = send_test_message(TranscodeComplete, message, %{})
      assert ActionStates.ok?(file_set.id, TranscodeComplete)

      assert FileSets.get_file_set(file_set.id)
             |> FileSets.derivative("playlist") ==
               "s3://#{@streaming_bucket}/event-test/small.m3u8"
    end
  end

  describe "transcode duration" do
    setup %{message_file: file} do
      file_set =
        file_set_fixture(
          core_metadata: %{
            mime_type: "video/mp4",
            location: "s3://#{@ingest_bucket}/small.m4v",
            original_filename: "small.m4v"
          }
        )

      message =
        Path.join("test/fixtures", file)
        |> File.read!()
        |> String.replace(~r/PRESERVATION_BUCKET/, @preservation_bucket)
        |> String.replace(~r/STREAMING_BUCKET/, @streaming_bucket)
        |> Jason.decode!(keys: :atoms)
        |> AtomicMap.convert(safe: false)
        |> put_in([:detail, :user_metadata, :file_set_id], file_set.id)

      :telemetry.attach(
        "transcode-duration-test",
        [:meadow, :pipeline, :transcode, :complete],
        fn _event, measurements, metadata, owner ->
          send(owner, {:transcode_complete, measurements, metadata})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("transcode-duration-test") end)

      {:ok, %{file_set: file_set, message: message}}
    end

    @tag message_file: "transcode/complete.json"
    test "measures from the start time MediaConvert handed back", %{
      file_set: file_set,
      message: message
    } do
      started_at = System.os_time(:millisecond) - :timer.minutes(5)

      message =
        put_in(message, [:detail, :user_metadata, :transcode_started_at], to_string(started_at))

      send_test_message(TranscodeComplete, message, %{})

      assert_received {:transcode_complete, %{duration_ms: duration}, metadata}
      assert duration >= :timer.minutes(5)
      assert duration < :timer.minutes(6)
      assert metadata.media_type == "video"
      assert metadata.outcome == "ok"
      assert metadata.file_set_id == file_set.id
    end

    @tag message_file: "transcode/complete.json"
    test "falls back to the CreateTranscodeJob action state when the metadata is absent",
         %{file_set: file_set, message: message} do
      ActionStates.set_state!(file_set, CreateTranscodeJob, "ok")

      send_test_message(TranscodeComplete, message, %{})

      assert_received {:transcode_complete, %{duration_ms: duration}, _metadata}
      assert duration >= 0
      assert duration < :timer.minutes(1)
    end

    @tag message_file: "transcode/complete.json"
    test "emits nothing when neither bookend is available", %{message: message} do
      send_test_message(TranscodeComplete, message, %{})

      refute_received {:transcode_complete, _, _}
    end

    @tag message_file: "transcode/complete.json"
    test "discards an implausible duration rather than publishing it", %{message: message} do
      # A start time in the future means the two ends did not pair up.
      started_at = System.os_time(:millisecond) + :timer.hours(1)

      message =
        put_in(message, [:detail, :user_metadata, :transcode_started_at], to_string(started_at))

      send_test_message(TranscodeComplete, message, %{})

      refute_received {:transcode_complete, _, _}
    end

    @tag message_file: "transcode/error.json"
    test "records the outcome of a failed transcode", %{message: message} do
      started_at = System.os_time(:millisecond) - :timer.minutes(2)

      message =
        put_in(message, [:detail, :user_metadata, :transcode_started_at], to_string(started_at))

      send_test_message(TranscodeComplete, message, %{})

      assert_received {:transcode_complete, _measurements, %{outcome: "error"}}
    end
  end
end
