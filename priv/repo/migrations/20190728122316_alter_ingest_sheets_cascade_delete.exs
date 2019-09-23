defmodule Meadow.Repo.Migrations.AlterIngestSheetsCascadeDelete do
  use Ecto.Migration

  def change do
    drop(constraint(:ingest_sheets, "ingest_sheets_project_id_fkey"))

    alter table(:ingest_sheets) do
      modify :project_id, references(:projects, on_delete: :delete_all)
      add :state, :string
    end
  end
end
