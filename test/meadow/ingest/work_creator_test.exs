defmodule Meadow.Ingest.WorkCreatorTest do
  use Meadow.IngestCase, async: false
  use Meadow.S3Case
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Ingest.{Progress, Sheets, SheetsToWorks, WorkCreator}
  alias Meadow.Pipeline.Actions.Dispatcher
  alias Meadow.Repo

  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  @state %{batch_size: 20, works_per_tick: 20, interval: 500, status: :running}
  @vtt_fixture "Donohue_002_01.vtt"
  @ingest_bucket Meadow.Config.ingest_bucket()
  @streaming_bucket Meadow.Config.streaming_bucket()

  describe "normal operation" do
    setup %{ingest_sheet: sheet} do
      sheet_with_project = Sheets.get_ingest_sheet_with_project!(sheet.id)

      upload_object(
        @ingest_bucket,
        "#{sheet_with_project.project.folder}/#{@vtt_fixture}",
        File.read!("test/fixtures/#{@vtt_fixture}")
      )

      on_exit(fn ->
        empty_bucket(@ingest_bucket)
        empty_bucket(@streaming_bucket)
      end)
    end

    test "create_works/1", %{ingest_sheet: sheet} do
      assert Works.list_works() |> length() == 0
      SheetsToWorks.create_works_from_ingest_sheet(sheet)

      assert WorkCreator.create_works(@state) == {:noreply, @state}

      with works <- Works.list_works() do
        assert works |> length() == 2
        assert works |> Enum.map(& &1.work_type.id) |> Enum.sort() == ["IMAGE", "VIDEO"]

        assert works
               |> Enum.find(fn w -> w.work_type.id == "IMAGE" end)
               |> Map.get(:representative_file_set_id)
               |> FileSets.get_file_set!()
               |> Map.get(:accession_number)
               |> String.ends_with?("Donohue_001_03")

        assert is_nil(
                 works
                 |> Enum.find(fn w -> w.work_type.id == "VIDEO" end)
                 |> Map.get(:representative_file_set_id)
               )

        assert %{type: "webvtt", value: _} =
                 Enum.find(works, fn w -> w.work_type.id == "VIDEO" end)
                 |> Map.get(:id)
                 |> Works.with_file_sets()
                 |> Map.get(:file_sets)
                 |> List.first()
                 |> Map.get(:structural_metadata)
      end
    end

    test "failure", %{ingest_sheet: sheet} do
      with %{ingest_sheet_rows: [row | _]} <- Repo.preload(sheet, :ingest_sheet_rows) do
        file_set_fixture(accession_number: row.file_set_accession_number)
        SheetsToWorks.create_works_from_ingest_sheet(sheet)

        assert WorkCreator.create_works(@state) == {:noreply, @state}
        assert Works.list_works() |> length() == 1

        assert ["CreateWork" | Dispatcher.all_progress_actions()]
               |> Enum.all?(fn action ->
                 Progress.get_entry(row, action) |> Map.get(:status) == "error"
               end)
      end
    end
  end

  test "concurrency", %{ingest_sheet: sheet} do
    Sandbox.mode(Meadow.Repo, {:shared, self()})
    SheetsToWorks.create_works_from_ingest_sheet(sheet)

    log =
      capture_log(fn ->
        Enum.map(1..5, fn _ ->
          Task.async(fn -> WorkCreator.create_works(%{batch_size: 20}) end)
        end)
        |> Task.await_many()

        assert Works.list_works() |> length() == 2
      end)

    assert Regex.scan(~r/Creating work [A-Z0-9]+_Donohue_001 with 4 file sets/, log)
           |> length() == 1
  end
end
