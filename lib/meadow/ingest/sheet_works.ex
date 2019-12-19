defmodule Meadow.Ingest.SheetWorks do
  @moduledoc """
  Context for sheet_works schema
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.{FileSets.FileSet, Works.Work}
  alias Meadow.Ingest.Schemas.{Row, Sheet, SheetWorks}
  alias Meadow.Repo

  def ingest_sheet_for(%FileSet{} = file_set), do: ingest_sheet_for_file_set(file_set.id)

  def ingest_sheet_for(%Work{} = work), do: ingest_sheet_for_work(work.id)

  def ingest_sheet_for_file_set(file_set_id) do
    from(
      fs in FileSet,
      join: iw in SheetWorks,
      on: iw.work_id == fs.work_id,
      join: sheets in Sheet,
      on: sheets.id == iw.sheet_id,
      where: fs.id == ^file_set_id,
      select: sheets
    )
    |> Repo.one()
  end

  def ingest_sheet_for_work(work_id) do
    from(
      iw in SheetWorks,
      join: sheets in Sheet,
      on: sheets.id == iw.sheet_id,
      where: iw.work_id == ^work_id,
      select: sheets
    )
    |> Repo.one()
  end

  def file_sets_and_rows(ingest_sheet) do
    from(f in FileSet,
      as: :file_set,
      join: w in Work,
      on: w.id == f.work_id,
      join: iw in SheetWorks,
      on: iw.work_id == w.id,
      join: r in Row,
      as: :row,
      on:
        r.sheet_id == iw.sheet_id and
          r.file_set_accession_number == f.accession_number,
      where: r.sheet_id == ^ingest_sheet.id
    )
  end

  def link_works_to_ingest_sheet(works, %Sheet{} = ingest_sheet) do
    SheetWorks
    |> Repo.insert_all(
      works
      |> Enum.map(fn work ->
        [sheet_id: ingest_sheet.id, work_id: work.id]
      end)
    )

    works
  end
end
