defmodule Meadow.Repo.Migrations.ChangeIngestJobTableAddErrors do
  use Ecto.Migration

  def change do
    alter table(:ingest_jobs) do
      add :file_errors, {:array, :string}, default: []
    end
  end
end
