defmodule Meadow.Pipeline.Actions.FileSetCompleteTest do
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.FileSetComplete

  import ExUnit.CaptureLog

  test "process/2" do
    %{id: file_set_id} = file_set_fixture()

    assert {:ok, %{id: ^file_set_id}, %{}} =
             send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})

    assert(ActionStates.ok?(file_set_id, FileSetComplete))

    assert capture_log(fn ->
             send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})
           end) =~ "Skipping #{FileSetComplete} for #{file_set_id} - already complete"
  end

  describe "telemetry" do
    setup do
      owner = self()

      :telemetry.attach_many(
        "file-set-complete-test",
        [[:meadow, :pipeline, :action, :stop], [:meadow, :pipeline, :file_set, :complete]],
        fn event, measurements, metadata, _ ->
          send(owner, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("file-set-complete-test") end)
      :ok
    end

    test "completing a file set re-emits its end-to-end pipeline duration" do
      %{id: file_set_id} = file_set_fixture()

      send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})

      # Only reached when the stop event carries file_set_id through from the span's
      # start metadata; without it the handler cannot look the file set up and this
      # event silently never fires.
      assert_received {:telemetry, [:meadow, :pipeline, :file_set, :complete],
                       %{duration_ms: elapsed}, _metadata}

      assert is_integer(elapsed) and elapsed >= 0
    end

    test "the span carries the action module rather than nothing" do
      %{id: file_set_id} = file_set_fixture()

      send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})

      assert_received {:telemetry, [:meadow, :pipeline, :action, :stop], _measurements, metadata}
      assert metadata.action == FileSetComplete
      assert metadata.outcome == "ok"
    end
  end
end
