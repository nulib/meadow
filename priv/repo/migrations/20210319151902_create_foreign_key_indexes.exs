defmodule Meadow.Repo.Migrations.CreateForeignKeyIndexes do
  use Ecto.Migration

  def change do
    create(index(:collections, [:representative_work_id]))
    create(index(:works, [:collection_id]))
    create(index(:works, [:ingest_sheet_id]))
    create(index(:works, [:representative_file_set_id]))
    create(index(:file_sets, [:work_id]))
    create(index(:ingest_sheets, [:project_id]))
  end
end
