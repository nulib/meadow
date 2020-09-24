defmodule Meadow.Ingest.WorkCreatorTest do
  use Meadow.IngestCase
  alias Meadow.Data.Works
  alias Meadow.Ingest.{SheetsToWorks, WorkCreator}

  @args [works_per_tick: 20, interval: 500]

  setup do
    worker = start_supervised!({WorkCreator, @args})
    %{worker: worker}
  end

  test "handle_info/2", %{ingest_sheet: sheet} do
    assert Works.list_works() |> length() == 0
    SheetsToWorks.create_works_from_ingest_sheet(sheet)
    :timer.sleep(1000)
    assert Works.list_works() |> length() == 2
  end
end
