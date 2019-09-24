defmodule Meadow.Repo.Migrations.AlterIngestSheetsUrlType do
  use Ecto.Migration

  def change do
    alter table(:ingest_sheets) do
      modify :presigned_url, :text
    end
  end
end
