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
end
