defmodule Meadow.Ingest.WorkCreatorTest do
  use Meadow.IngestCase, async: false
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.Works
  alias Meadow.Ingest.{SheetsToWorks, WorkCreator}

  import Assertions
  import ExUnit.CaptureLog

  @args [works_per_tick: 20, interval: 500]

  describe "normal operation" do
    setup do
      worker = start_supervised!({WorkCreator, @args})
      %{worker: worker}
    end

    test "handle_info/2", %{ingest_sheet: sheet} do
      assert Works.list_works() |> length() == 0
      SheetsToWorks.create_works_from_ingest_sheet(sheet)

      assert_async(timeout: 1500, sleep_time: 150) do
        assert Works.list_works() |> length() == 2
      end
    end
  end

  test "concurrency", %{ingest_sheet: sheet} do
    Sandbox.mode(Meadow.Repo, {:shared, self()})
    SheetsToWorks.create_works_from_ingest_sheet(sheet)

    log =
      capture_log(fn ->
        Enum.each(1..5, fn _ ->
          spawn(fn -> WorkCreator.create_works(%{batch_size: 20}) end)
        end)

        assert_async(timeout: 1500, sleep_time: 150) do
          assert Works.list_works() |> length() == 2
        end
      end)

    assert Regex.scan(~r/Creating work [A-Z0-9]+_Donohue_001 with 4 file sets/, log)
           |> length() == 1
  end
end
