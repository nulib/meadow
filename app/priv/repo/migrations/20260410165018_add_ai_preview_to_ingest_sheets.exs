defmodule Meadow.Repo.Migrations.AddAiPreviewToIngestSheets do
  use Ecto.Migration

  def change do
    alter table(:ingest_sheets) do
      add :ai_preview, :map
    end
  end
end
