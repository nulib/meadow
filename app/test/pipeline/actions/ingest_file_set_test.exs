defmodule Meadow.Pipeline.Actions.IngestFileSetTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.IngestFileSet

  import ExUnit.CaptureLog

  describe "file set exists" do
    test "process/2" do
      %{id: file_set_id} = file_set_fixture()

      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(IngestFileSet, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, IngestFileSet))

      assert capture_log(fn ->
               send_test_message(IngestFileSet, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{IngestFileSet} for #{file_set_id} - already complete"
    end
  end

  describe "file set does not exist" do
    test "process/2" do
      nonexistent_file_set_id = Ecto.UUID.generate()

      assert capture_log(fn ->
               assert {:error, _reason} =
                        send_test_message(
                          IngestFileSet,
                          %{file_set_id: nonexistent_file_set_id},
                          %{}
                        )
             end) =~
               "Marking #{IngestFileSet} for #{nonexistent_file_set_id} as error because the file set was not found"
    end
  end
end
