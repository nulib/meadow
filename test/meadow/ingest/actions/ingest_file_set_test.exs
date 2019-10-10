defmodule Meadow.Ingest.Actions.IngestFileSetTest do
  use Meadow.DataCase
  alias Meadow.Data.AuditEntries
  alias Meadow.Ingest.Actions.IngestFileSet
  import ExUnit.CaptureLog

  @object_id "01DPPFNZ55TABJ74NV9H4ZKF1B"
  test "process/2" do
    assert(IngestFileSet.process(%{file_set_id: @object_id}, %{}) == :ok)
    assert(AuditEntries.ok?(@object_id, IngestFileSet))

    assert capture_log(fn ->
             IngestFileSet.process(%{file_set_id: @object_id}, %{})
           end) =~ "Skipping #{IngestFileSet} for #{@object_id} – already complete"
  end
end
