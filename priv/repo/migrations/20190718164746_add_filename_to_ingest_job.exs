defmodule Meadow.Repo.Migrations.AddFilenameToIngestJob do
  use Ecto.Migration

  def change do
    alter table("ingest_jobs") do
      add :filename, :string
    end
  end
end
