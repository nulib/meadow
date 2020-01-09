defmodule Meadow.Pipeline.Actions.UpdateSheetStatusTest do
  use Meadow.DataCase
  alias Meadow.Pipeline.Actions.UpdateSheetStatus
  import ExUnit.CaptureLog

  test "process/2" do
    object = ingest_sheet_fixture()

    assert capture_log(fn ->
             assert(
               UpdateSheetStatus.process(%{}, %{
                 ingest_sheet: object.id,
                 ingest_sheet_row: "0",
                 process: "test",
                 status: "tested"
               }) == :ok
             )
           end) =~ "Setting status tested on row 0 of sheet #{object.id} from test"
  end
end
