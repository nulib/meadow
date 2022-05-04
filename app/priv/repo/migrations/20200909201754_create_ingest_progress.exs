defmodule Meadow.Repo.Migrations.CreateIngestProgress do
  use Ecto.Migration

  def change do
    create table(:ingest_progress, primary_key: false) do
      add :row_id, references(:ingest_sheet_rows, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :action, :string, primary_key: true
      add :status, :string
      timestamps()
    end
  end
end
