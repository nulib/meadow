defmodule Meadow.Repo.Migrations.AddAiIngestToWorks do
  use Ecto.Migration

  def change do
    alter table(:works) do
      add :ai_ingest, :boolean, default: false, null: false
    end
  end
end
