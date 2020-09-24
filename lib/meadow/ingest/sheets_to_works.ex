defmodule Meadow.Ingest.SheetsToWorks do
  @moduledoc """
  Functions to group Rows into Works and FileSets
  and create the resulting database records
  """
  import Ecto.Query, warn: false
  alias Meadow.Ingest.{Progress, Rows, Sheets, WorkCreator}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Repo

  def create_works_from_ingest_sheet(%Sheet{} = ingest_sheet, :sync) do
    create_works_from_ingest_sheet(ingest_sheet)

    Progress.get_pending_work_entries(ingest_sheet.id, :all)
    |> Repo.preload(row: :sheet)
    |> WorkCreator.create_works()

    Sheets.get_ingest_sheet!(ingest_sheet.id)
  end

  def create_works_from_ingest_sheet(%Sheet{} = ingest_sheet) do
    ingest_sheet
    |> initialize_progress()

    ingest_sheet
  end

  def group_by_works(%Sheet{} = ingest_sheet) do
    Rows.list_ingest_sheet_rows(sheet: ingest_sheet)
    |> Enum.group_by(fn row -> row |> Row.field_value(:work_accession_number) end)
  end

  def initialize_progress(ingest_sheet) do
    with groups <- group_by_works(ingest_sheet) do
      groups
      |> Enum.flat_map(fn {_, rows} ->
        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, index} -> {row.id, index == 0} end)
      end)
      |> Progress.initialize_entries()

      groups
    end
  end
end
