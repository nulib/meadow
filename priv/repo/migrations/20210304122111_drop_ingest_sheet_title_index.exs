defmodule Meadow.Repo.Migrations.DropIngestSheetTitleIndex do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:ingest_sheets, [:title])
    create_if_not_exists index(:ingest_sheets, [:title])
  end
end
