defmodule Meadow.Repo.Migrations.CreateIngestSheetStatus do
  use Ecto.Migration

  def change do
    create table(:ingest_sheet_status, primary_key: false) do
      add(:sheet_id, :string, null: false, primary_key: true)
      add(:row, :integer, primary_key: true)
      add(:status, :string, null: false, default: "initialized")
    end
  end
end
