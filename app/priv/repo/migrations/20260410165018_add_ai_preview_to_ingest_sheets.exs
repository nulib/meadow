defmodule Meadow.Repo.Migrations.AddAiPreviewToIngestSheets do
  use Ecto.Migration

  def change do
    alter table(:ingest_sheets) do
      # add :ai_cost_actual, :float, null: false, default: 0.0
      # add :ai_cost_estimate, :float, null: false, default: 0.0
      add :ai_preview, {:array, :map}, default: [], null: false
    end
  end
end
