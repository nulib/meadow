defmodule Meadow.Repo.Migrations.ChangeIngestJobStateToStruct do
  use Ecto.Migration

  def change do
    alter table(:ingest_jobs) do
      remove :state
      add :state, :jsonb
    end
  end
end
