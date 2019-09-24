defmodule Meadow.Repo.Migrations.CreateIngestSheets do
  use Ecto.Migration

  def change do
    create table(:ingest_sheets) do
      add :name, :string
      add :presigned_url, :string

      add :project_id, references("projects"), null: false

      timestamps()
    end

    create unique_index(:ingest_sheets, [:name])
  end
end
