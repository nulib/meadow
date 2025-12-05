defmodule Meadow.Ingest.WorkCreatorTest do
  use Meadow.DataCase, async: false
  use Meadow.IngestCase, async: false
  use Meadow.S3Case
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Ingest.{Progress, Sheets, SheetsToWorks, WorkCreator}
  alias Meadow.Pipeline.Dispatcher
  alias Meadow.Repo

  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  @state %{batch_size: 20, works_per_tick: 20, interval: 500, status: :running}
  @vtt_fixture "Donohue_002_01.vtt"
  @transcription_fixture "transcription.txt"
  @ingest_bucket Meadow.Config.ingest_bucket()
  @streaming_bucket Meadow.Config.streaming_bucket()
  @derivatives_bucket Meadow.Config.derivatives_bucket()

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

  describe "transcription annotations from ingest sheet" do
    setup do
      sheet = ingest_sheet_rows_fixture("test/fixtures/ingest_sheet_transcription.csv")

      sheet
      |> Sheets.change_ingest_sheet_validation_state!(%{file: "pass", rows: "pass", overall: "pass"})
      |> Repo.preload(:ingest_sheet_rows)
      |> Map.get(:ingest_sheet_rows)
      |> Enum.each(fn row -> Meadow.Ingest.Rows.change_ingest_sheet_row_validation_state(row, "pass") end)

      {:ok, ingest_sheet: sheet}
    end

    setup %{ingest_sheet: sheet} do
      sheet_with_project = Sheets.get_ingest_sheet_with_project!(sheet.id)

      upload_object(
        @ingest_bucket,
        "#{sheet_with_project.project.folder}/#{@transcription_fixture}",
        File.read!("test/fixtures/#{@transcription_fixture}")
      )

      upload_object(
        @ingest_bucket,
        "#{sheet_with_project.project.folder}/#{@vtt_fixture}",
        File.read!("test/fixtures/#{@vtt_fixture}")
      )

      on_exit(fn ->
        empty_bucket(@ingest_bucket)
        empty_bucket(@derivatives_bucket)
      end)
    end

    test "creates transcription annotation for IMAGE work with .txt file", %{
      ingest_sheet: sheet
    } do
      SheetsToWorks.create_works_from_ingest_sheet(sheet)
      WorkCreator.create_works(@state)

      # Find the IMAGE work
      image_work = Works.list_works() |> Enum.find(fn w -> w.work_type.id == "IMAGE" end)
      assert image_work

      # Find the file set with the transcription (first one in the CSV)
      file_set =
        image_work.id
        |> Works.with_file_sets()
        |> Map.get(:file_sets)
        |> Enum.find(fn fs -> String.ends_with?(fs.accession_number, "Donohue_001_01555") end)

      # Verify transcription annotation was created
      annotations = FileSets.list_annotations(file_set)
      assert length(annotations) == 1

      annotation = List.first(annotations)
      assert annotation.type == "transcription"
      assert annotation.status == "completed"
      assert annotation.s3_location

      # Verify content was copied to S3
      {:ok, content} = FileSets.read_annotation_content(annotation)
      assert content == "This is the transcription for the image!"
    end
  end
end
