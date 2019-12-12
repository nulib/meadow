defmodule Meadow.Ingest.Actions.IngestFileSetTest do
  use Meadow.DataCase
  alias Meadow.Data.ActionStates
  alias Meadow.Ingest.Actions.IngestFileSet
  import ExUnit.CaptureLog

  test "process/2" do
    object = file_set_fixture()

    assert(IngestFileSet.process(%{file_set_id: object.id}, %{}) == :ok)
    assert(ActionStates.ok?(object.id, IngestFileSet))

    assert capture_log(fn ->
             IngestFileSet.process(%{file_set_id: object.id}, %{})
           end) =~ "Skipping #{IngestFileSet} for #{object.id} – already complete"
  end
end
