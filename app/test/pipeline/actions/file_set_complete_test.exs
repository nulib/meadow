defmodule Meadow.Pipeline.Actions.FileSetCompleteTest do
  use Meadow.DataCase
  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.FileSetComplete
  import ExUnit.CaptureLog

  test "process/2" do
    object = file_set_fixture()

    assert(FileSetComplete.process(%{file_set_id: object.id}, %{}) == :ok)
    assert(ActionStates.ok?(object.id, FileSetComplete))

    assert capture_log(fn ->
             FileSetComplete.process(%{file_set_id: object.id}, %{})
           end) =~ "Skipping #{FileSetComplete} for #{object.id} - already complete"
  end
end
