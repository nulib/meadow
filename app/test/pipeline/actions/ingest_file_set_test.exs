defmodule Meadow.Pipeline.Actions.IngestFileSetTest do
  use Meadow.DataCase
  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.IngestFileSet
  import ExUnit.CaptureLog

  describe "file set exists" do
    test "process/2" do
      object = file_set_fixture()

      assert(IngestFileSet.process(%{file_set_id: object.id}, %{}) == :ok)
      assert(ActionStates.ok?(object.id, IngestFileSet))

      assert capture_log(fn ->
               IngestFileSet.process(%{file_set_id: object.id}, %{})
             end) =~ "Skipping #{IngestFileSet} for #{object.id} - already complete"
    end
  end

  describe "file set does not exist" do
    test "process/2" do
      nonexistent_file_set_id = Ecto.UUID.generate()
      assert capture_log(fn ->
        assert({:error, _reason} = IngestFileSet.process(%{file_set_id: nonexistent_file_set_id}, %{}))
      end) =~ "Marking #{IngestFileSet} for #{nonexistent_file_set_id} as error because the file set was not found"
    end
  end
end
