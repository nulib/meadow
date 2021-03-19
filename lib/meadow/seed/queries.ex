defmodule Meadow.Seed.Queries do
  @moduledoc """
  Module providing the composable query functions used by Meadow.Seed.Export
  """

  alias Meadow.Data.Schemas.{ActionState, Collection, ControlledTermCache, FileSet, Work}
  alias Meadow.Ingest.Schemas.{Progress, Project, Row, Sheet}

  import Ecto.Query

  def collections(_) do
    from(c in Collection, select: c)
  end

  def controlled_term_cache(_) do
    from(ct in ControlledTermCache, select: ct)
  end

  def nul_authorities(_) do
    from(a in NUL.Schemas.AuthorityRecord, select: a)
  end

  def ingest_sheet_projects(ingest_sheet_ids) do
    from(s in Sheet,
      join: p in Project,
      on: p.id == s.project_id,
      where: s.id in ^ingest_sheet_ids,
      distinct: true,
      select: p
    )
  end

  def ingest_sheets(ingest_sheet_ids) do
    from(s in Sheet,
      where: s.id in ^ingest_sheet_ids,
      distinct: true,
      select: s
    )
  end

  def ingest_sheet_rows(ingest_sheet_ids) do
    from(r in Row,
      where: r.sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: r
    )
  end

  def ingest_sheet_progress(ingest_sheet_ids) do
    from(r in Row,
      join: p in Progress,
      on: p.row_id == r.id,
      where: r.sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: p
    )
  end

  def ingest_sheet_works(ingest_sheet_ids) do
    from(w in Work,
      where: w.ingest_sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: w
    )
  end

  def ingest_sheet_file_sets(ingest_sheet_ids) do
    from(w in Work,
      join: fs in FileSet,
      on: fs.work_id == w.id,
      where: w.ingest_sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: fs
    )
  end

  def ingest_sheet_action_states(ingest_sheet_ids) do
    from(w in Work,
      join: fs in FileSet,
      on: fs.work_id == w.id,
      join: as in ActionState,
      on: as.object_id in [fs.id, w.id],
      where: w.ingest_sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: as
    )
  end

  def standalone_works(work_ids) do
    from(w in Work,
      where: w.id in ^work_ids,
      distinct: true,
      select: w
    )
  end

  def standalone_file_sets(work_ids) do
    from(fs in FileSet,
      where: fs.work_id in ^work_ids,
      distinct: true,
      select: fs
    )
  end

  def standalone_action_states(work_ids) do
    from(w in Work,
      join: fs in FileSet,
      on: fs.work_id == w.id,
      join: as in ActionState,
      on: as.object_id in [fs.id, w.id],
      where: w.id in ^work_ids,
      distinct: true,
      select: as
    )
  end
end
