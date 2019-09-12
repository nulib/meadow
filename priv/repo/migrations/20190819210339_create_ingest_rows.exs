defmodule Meadow.Repo.Migrations.CreateIngestRows do
  use Ecto.Migration

  def change do
    create table(:ingest_rows, primary_key: false) do
      add :state, :string
      add :errors, :jsonb
      add :fields, :jsonb

      add :ingest_job_id, references("ingest_jobs", on_delete: :delete_all),
        null: false,
        primary_key: true

      add :row, :integer, null: false, primary_key: true

      timestamps()
    end

    create unique_index(:ingest_rows, [:ingest_job_id, :row])
  end
end
