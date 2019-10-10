defmodule Meadow.Repo.Migrations.AddIngestSheetWorks do
  use Ecto.Migration

  def change do
    create table(:ingest_sheet_works, primary_key: false) do
      add :work_id, :binary_id, null: false, primary_key: true
      add :ingest_sheet_id, :binary_id, null: false, primary_key: true
    end
  end
end
