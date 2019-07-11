defmodule Meadow.Repo.Migrations.CreateIngestJobs do
  use Ecto.Migration

  def change do
    create table(:ingest_jobs) do
      add :name, :string
      add :presigned_url, :string

      add :project_id, references("projects"), null: false

      timestamps()
    end

    create unique_index(:ingest_jobs, [:name])
  end
end
