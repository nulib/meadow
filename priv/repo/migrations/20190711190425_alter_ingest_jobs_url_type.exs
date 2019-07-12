defmodule Meadow.Repo.Migrations.AlterIngestJobsUrlType do
  use Ecto.Migration

  def change do
    alter table(:ingest_jobs) do
      modify :presigned_url, :text
    end
  end
end
