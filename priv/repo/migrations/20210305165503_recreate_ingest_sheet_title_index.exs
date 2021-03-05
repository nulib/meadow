defmodule Meadow.Repo.Migrations.RecreateIngestSheetTitleIndex do
  use Ecto.Migration

  def change do
    drop_if_exists index(:ingest_sheets, [:title])
    create_if_not_exists unique_index(:ingest_sheets, [:title])
  end
end
