defmodule Meadow.Repo.Migrations.AddFilenameToIngestSheet do
  use Ecto.Migration

  def change do
    alter table("ingest_sheets") do
      add :filename, :string
    end
  end
end
