defmodule Meadow.Ingest.Actions.FileSetCompleteTest do
  use Meadow.DataCase
  alias Meadow.Data.AuditEntries
  alias Meadow.Ingest.Actions.FileSetComplete
  import ExUnit.CaptureLog

  test "process/2" do
    object = file_set_fixture()

    assert(FileSetComplete.process(%{file_set_id: object.id}, %{}) == :ok)
    assert(AuditEntries.ok?(object.id, FileSetComplete))

    assert capture_log(fn ->
             FileSetComplete.process(%{file_set_id: object.id}, %{})
           end) =~ "Skipping #{FileSetComplete} for #{object.id} – already complete"
  end
end
