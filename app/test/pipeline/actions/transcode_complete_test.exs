defmodule Meadow.Pipeline.Actions.TranscodeCompleteTest do
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.TranscodeComplete

  describe "process AWS MediaConvert Event" do
    setup %{message_file: file} do
      file_set = file_set_fixture()

      message =
        Path.join("test/fixtures", file)
        |> File.read!()
        |> Jason.decode!(keys: :atoms)
        |> AtomicMap.convert(safe: false)
        |> put_in([:detail, :user_metadata, :file_set_id], file_set.id)

      {:ok, %{file_set: file_set, message: message}}
    end

    @tag message_file: "transcode/error.json"
    test "error", %{file_set: file_set, message: message} do
      assert {:error, error, %{context: "Test"}} = TranscodeComplete.process(message, %{})
      assert error |> String.contains?("Failed to read data")

      with state <- ActionStates.get_latest_state(file_set.id, TranscodeComplete) do
        assert state.outcome == "error"
        assert state.notes |> String.contains?("Failed to read data")
      end
    end

    @tag message_file: "transcode/complete.json"
    test "complete", %{file_set: file_set, message: message} do
      assert {:ok, _, %{context: "Test"}} = TranscodeComplete.process(message, %{})
      assert ActionStates.ok?(file_set.id, TranscodeComplete)

      assert FileSets.get_file_set(file_set.id)
             |> Map.get(:derivatives)
             |> Map.get("playlist") == "s3://test-streaming/event-test/small.m3u8"
    end
  end
end
