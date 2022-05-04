defmodule Meadow.Repo.Migrations.CreateIngestSheetRows do
  use Ecto.Migration

  def change do
    create table(:ingest_sheet_rows) do
      add(:sheet_id, references(:ingest_sheets, on_delete: :delete_all), null: false)
      add(:row, :integer, null: false)
      add(:state, :string)
      add(:errors, :jsonb)
      add(:fields, :jsonb)
      add(:file_set_accession_number, :string)
      timestamps()
    end

    create(unique_index(:ingest_sheet_rows, [:sheet_id, :row]))
  end
end
