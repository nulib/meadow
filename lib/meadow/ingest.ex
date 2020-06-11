defmodule Meadow.Ingest do
  @moduledoc """
  The PrimaryIngest context. Functions for dealing with Ingest, Sheets and Projects
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Repo

  def ingest_sheet_for_file_set(file_set_id) do
    FileSet
    |> preload(work: [:ingest_sheet])
    |> Repo.get!(file_set_id)
    |> Map.get(:work)
    |> Map.get(:ingest_sheet)
  end

  def get_file_sets_and_rows(%Sheet{} = sheet) do
    from([file_set: file_set, row: row] in file_sets_and_rows(sheet),
      select: %{file_set_id: file_set.id, row_num: row.row}
    )
    |> Repo.all()
  end

  def file_sets_and_rows(ingest_sheet) do
    from(f in FileSet,
      as: :file_set,
      join: w in Work,
      on: w.ingest_sheet_id == ^ingest_sheet.id,
      join: r in Row,
      as: :row,
      on: r.file_set_accession_number == f.accession_number,
      where: r.sheet_id == ^ingest_sheet.id
    )
  end

  # Dataloader

  def datasource do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _) do
    queryable
  end
end
