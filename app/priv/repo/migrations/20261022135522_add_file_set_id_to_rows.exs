defmodule Meadow.Repo.Migrations.AddFileSetIDToRows do
  use Ecto.Migration

  def up do
    alter table(:ingest_sheet_rows) do
      add :file_set_id, :binary_id
    end
    create index(:ingest_sheet_rows, [:file_set_id])
    execute """
      UPDATE ingest_sheet_rows r
      SET file_set_id = fs.id
      FROM file_sets fs
      JOIN works w ON w.id = fs.work_id
      WHERE r.sheet_id = w.ingest_sheet_id
        AND r.file_set_accession_number = fs.accession_number
        AND r.file_set_id IS DISTINCT FROM fs.id
    """
  end

  def down do
    execute "UPDATE ingest_sheet_rows SET file_set_id = NULL"
    drop index(:ingest_sheet_rows, [:file_set_id])
    alter table(:ingest_sheet_rows) do
      remove :file_set_id
    end
  end
end
