defmodule Meadow.Ingest.Actions.IngestFileSetTest do
  use Meadow.DataCase
  alias Meadow.Ingest.Actions.IngestFileSet

  test "process/2" do
    assert(IngestFileSet.process(%{file_set_id: "01DPPFNZ55TABJ74NV9H4ZKF1B"}, %{}) == :ok)
  end
end
