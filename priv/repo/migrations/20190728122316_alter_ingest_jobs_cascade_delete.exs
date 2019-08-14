defmodule Meadow.Repo.Migrations.AlterIngestJobsCascadeDelete do
  use Ecto.Migration

  def change do
    drop(constraint(:ingest_jobs, "ingest_jobs_project_id_fkey"))

    alter table(:ingest_jobs) do
      modify :project_id, references(:projects, on_delete: :delete_all)
      add :state, :string
    end
  end
end
