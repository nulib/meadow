defmodule Meadow.Repo.Migrations.CreateIngestSheetRows do
  use Ecto.Migration

  def change do
    create table(:ingest_sheet_rows, primary_key: false) do
      add :state, :string
      add :errors, :jsonb
      add :fields, :jsonb

      add :ingest_sheet_id, references("ingest_sheets", on_delete: :delete_all),
        null: false,
        primary_key: true

      add :row, :integer, null: false, primary_key: true

      timestamps()
    end

    create unique_index(:ingest_sheet_rows, [:ingest_sheet_id, :row])
  end
end
