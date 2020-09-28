defmodule Meadow.Ingest.ProgressTest do
  use Meadow.DataCase
  use Meadow.IngestCase

  alias Meadow.Ingest.{Progress, Rows}
  alias Meadow.Pipeline.Actions

  @bad_sheet_id "deadface-c0de-feed-cafe-addedbadbeef"

  describe "single row" do
    setup %{ingest_sheet: sheet} do
      {:ok, %{ingest_sheet: sheet}}
    end

    test "initialize_entry/1", %{ingest_sheet: sheet} do
      with [row | _] <- Rows.list_ingest_sheet_rows(sheet: sheet) do
        Progress.initialize_entry(row, true)
        assert Progress.get_entry(row, "CreateWork") |> Map.get(:status) == "pending"
      end
    end
  end

  describe "Meadow.Ingest.Progress" do
    setup %{ingest_sheet: sheet} do
      with rows <- Rows.list_ingest_sheet_rows(sheet: sheet) do
        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, index} -> {row.id, rem(index, 4) == 0} end)
        |> Progress.initialize_entries()

        {:ok, %{ingest_sheet: sheet, rows: rows}}
      end
    end

    test "get_entry/2", %{rows: [row | _]} do
      assert Progress.get_entry(row, "CreateWork") |> Map.get(:status) == "pending"
      assert Progress.get_entry(row.id, "CreateWork") |> Map.get(:status) == "pending"
    end

    test "get_pending_work_entries/2", %{ingest_sheet: %{id: sheet_id}, rows: [row | _]} do
      assert Progress.get_pending_work_entries(sheet_id, :all) |> length() == 2
      assert Progress.get_pending_work_entries(sheet_id, 1) |> length() == 1
      Progress.update_entry(row, "CreateWork", "in_process")
      assert Progress.get_pending_work_entries(sheet_id, :all) |> length() == 1
    end

    test "get_pending_work_entries/1", %{rows: [row | _]} do
      assert Progress.get_pending_work_entries(:all) |> length() == 2
      assert Progress.get_pending_work_entries(1) |> length() == 1
      Progress.update_entry(row, "CreateWork", "in_process")
      assert Progress.get_pending_work_entries(:all) |> length() == 1
    end

    test "update_entry/3", %{rows: [row | _]} do
      Progress.update_entry(row, "CreateWork", "ok")
      assert Progress.get_entry(row, "CreateWork") |> Map.get(:status) == "ok"

      Progress.update_entry(row, Actions.IngestFileSet, "ok")
      assert Progress.get_entry(row.id, Actions.IngestFileSet) |> Map.get(:status) == "ok"
    end

    test "update_entries/3", %{ingest_sheet: sheet} do
      Progress.get_entries(sheet)
      |> Progress.update_entries("CreateWork", "processing")
      |> Enum.each(fn result ->
        assert result.status == "processing"
      end)
    end

    test "action_count/1", %{ingest_sheet: sheet} do
      assert Progress.action_count(sheet) == 37
      assert Progress.action_count(@bad_sheet_id) == 0
    end

    test "completed_count/1", %{ingest_sheet: sheet, rows: [row | _]} do
      assert Progress.completed_count(sheet) == 0
      Progress.update_entry(row, "CreateWork", "ok")
      Progress.update_entry(row, Actions.IngestFileSet, "ok")
      assert Progress.completed_count(sheet) == 2
    end

    test "file_set_count/1", %{ingest_sheet: sheet} do
      assert Progress.file_set_count(sheet) == 7
    end

    test "completed_file_set_count/1", %{ingest_sheet: sheet, rows: [row | _]} do
      assert Progress.completed_file_set_count(sheet) == 0
      Progress.update_entry(row, Actions.FileSetComplete, "ok")
      assert Progress.completed_file_set_count(sheet) == 1
    end

    test "pipeline_progress/1", %{ingest_sheet: sheet} do
      with progress <- Progress.pipeline_progress(sheet) do
        assert progress.sheet_id == sheet.id
        assert progress.total_file_sets == 7
        assert progress.completed_file_sets == 0
        assert progress.total_actions == 37
        assert progress.completed_actions == 0
        assert progress.percent_complete == 0.0
      end

      Progress.get_entries(sheet)
      |> Enum.take(20)
      |> Enum.each(fn entry -> Progress.update_entry(entry.row_id, entry.action, "ok") end)

      with progress <- Progress.pipeline_progress(sheet) do
        assert progress.completed_file_sets == 4
        assert progress.completed_actions == 20
        assert_in_delta(progress.percent_complete, 54.0, 0.10)
      end

      Progress.get_entries(sheet)
      |> Enum.each(fn entry -> Progress.update_entry(entry.row_id, entry.action, "ok") end)

      with progress <- Progress.pipeline_progress(sheet) do
        assert progress.completed_file_sets == 7
        assert progress.completed_actions == 37
        assert progress.percent_complete == 100.0
      end

      with progress <- Progress.pipeline_progress(@bad_sheet_id) do
        assert progress.sheet_id == @bad_sheet_id
        assert progress.total_file_sets == 0
        assert progress.completed_file_sets == 0
        assert progress.total_actions == 0
        assert progress.completed_actions == 0
        assert progress.percent_complete == 0.0
      end
    end
  end
end
