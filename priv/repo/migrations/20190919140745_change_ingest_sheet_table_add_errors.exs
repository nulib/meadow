defmodule Meadow.Repo.Migrations.ChangeIngestSheetTableAddErrors do
  use Ecto.Migration

  def change do
    alter table(:ingest_sheets) do
      add :file_errors, {:array, :string}, default: []
    end
  end
end
