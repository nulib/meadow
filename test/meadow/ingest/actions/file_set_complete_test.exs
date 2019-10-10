defmodule Meadow.Ingest.Actions.FileSetCompleteTest do
  use Meadow.DataCase
  alias Meadow.Data.AuditEntries
  alias Meadow.Ingest.Actions.FileSetComplete
  import ExUnit.CaptureLog

  @object_id "01DPPFNZ55TABJ74NV9H4ZKF1B"
  test "process/2" do
    assert(FileSetComplete.process(%{file_set_id: @object_id}, %{}) == :ok)
    assert(AuditEntries.ok?(@object_id, FileSetComplete))

    assert capture_log(fn ->
             FileSetComplete.process(%{file_set_id: @object_id}, %{})
           end) =~ "Skipping #{FileSetComplete} for #{@object_id} – already complete"
  end
end
