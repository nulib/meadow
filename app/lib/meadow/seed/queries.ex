defmodule Meadow.Seed.Queries do
  @moduledoc """
  Module providing the composable query functions used by Meadow.Seed.Export
  """

  alias Meadow.Data.Schemas.{ActionState, Collection, ControlledTermCache, FileSet, Work}
  alias Meadow.Ingest.Schemas.{Progress, Project, Row, Sheet}

  import Ecto.Query

  # Relational work metadata tables, exported alongside their works
  @work_metadata_schemas [
    descriptive_metadata: Meadow.Data.Schemas.WorkDescriptiveMetadata,
    administrative_metadata: Meadow.Data.Schemas.WorkAdministrativeMetadata,
    metadata_values: Meadow.Data.Schemas.MetadataValue,
    controlled_entries: Meadow.Data.Schemas.ControlledMetadataEntry,
    notes: Meadow.Data.Schemas.NoteEntry,
    related_urls: Meadow.Data.Schemas.RelatedURLEntry,
    dates_created: Meadow.Data.Schemas.DateCreatedEntry,
    nav_places: Meadow.Data.Schemas.NavPlaceEntry
  ]

  def work_metadata_schemas, do: @work_metadata_schemas

  @doc "Export names of the work metadata tables for the given work export (`:ingest_sheet_works` or `:standalone_works`)"
  def work_metadata_exports(prefix),
    do: Enum.map(@work_metadata_schemas, fn {name, _} -> :"#{prefix}_#{name}" end)

  for {name, schema} <- @work_metadata_schemas do
    def unquote(:"ingest_sheet_works_#{name}")([]), do: from(unquote(schema), limit: 0)

    def unquote(:"ingest_sheet_works_#{name}")(ingest_sheet_ids) do
      from(m in unquote(schema),
        join: w in Work,
        on: m.work_id == w.id,
        where: w.ingest_sheet_id in ^ingest_sheet_ids,
        select: m
      )
    end

    def unquote(:"standalone_works_#{name}")([]), do: from(unquote(schema), limit: 0)

    def unquote(:"standalone_works_#{name}")(work_ids) do
      from(m in unquote(schema), where: m.work_id in ^work_ids, select: m)
    end
  end

  def collections(_) do
    from(c in Collection, select: c)
  end

  def controlled_term_cache(_) do
    from(ct in ControlledTermCache, select: ct)
  end

  def nul_authorities(_) do
    from(a in NUL.Schemas.AuthorityRecord, select: a)
  end

  def ingest_sheet_projects([]), do: from(Project, limit: 0)

  def ingest_sheet_projects(ingest_sheet_ids) do
    from(s in Sheet,
      join: p in Project,
      on: p.id == s.project_id,
      where: s.id in ^ingest_sheet_ids,
      distinct: true,
      select: p
    )
  end

  def ingest_sheets([]), do: from(Sheet, limit: 0)

  def ingest_sheets(ingest_sheet_ids) do
    from(s in Sheet,
      where: s.id in ^ingest_sheet_ids,
      distinct: true,
      select: s
    )
  end

  def ingest_sheet_rows([]), do: from(Row, limit: 0)

  def ingest_sheet_rows(ingest_sheet_ids) do
    from(r in Row,
      where: r.sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: r
    )
  end

  def ingest_sheet_progress([]), do: from(Progress, limit: 0)

  def ingest_sheet_progress(ingest_sheet_ids) do
    from(r in Row,
      join: p in Progress,
      on: p.row_id == r.id,
      where: r.sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: p
    )
  end

  def ingest_sheet_works([]), do: from(Work, limit: 0)

  def ingest_sheet_works(ingest_sheet_ids) do
    from(w in Work,
      where: w.ingest_sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: w
    )
  end

  def ingest_sheet_file_sets([]), do: from(FileSet, limit: 0)

  def ingest_sheet_file_sets(ingest_sheet_ids) do
    from(w in Work,
      join: fs in FileSet,
      on: fs.work_id == w.id,
      where: w.ingest_sheet_id in ^ingest_sheet_ids,
      distinct: true,
      select: fs
    )
  end

  def ingest_sheet_action_states([]), do: from(ActionState, limit: 0)

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

  def standalone_works([]), do: from(Work, limit: 0)

  def standalone_works(work_ids) do
    from(w in Work,
      where: w.id in ^work_ids,
      distinct: true,
      select: w
    )
  end

  def standalone_file_sets([]), do: from(FileSet, limit: 0)

  def standalone_file_sets(work_ids) do
    from(fs in FileSet,
      where: fs.work_id in ^work_ids,
      distinct: true,
      select: fs
    )
  end

  def standalone_action_states([]), do: from(ActionState, limit: 0)

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
