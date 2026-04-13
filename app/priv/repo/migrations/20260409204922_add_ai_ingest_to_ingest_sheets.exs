defmodule Meadow.Repo.Migrations.AddAiIngestToIngestSheets do
  use Ecto.Migration

  def change do
    alter table(:ingest_sheets) do
      add :ai_ingest, :boolean, default: false, null: false
    end
  end
end
