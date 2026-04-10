defmodule Meadow.Repo.Migrations.ChangeAiPreviewToArray do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE ingest_sheets
    ALTER COLUMN ai_preview TYPE jsonb[]
    USING CASE WHEN ai_preview IS NOT NULL THEN ARRAY[ai_preview] ELSE NULL END
    """)
  end

  def down do
    execute("""
    ALTER TABLE ingest_sheets
    ALTER COLUMN ai_preview TYPE jsonb
    USING ai_preview[1]
    """)
  end
end
