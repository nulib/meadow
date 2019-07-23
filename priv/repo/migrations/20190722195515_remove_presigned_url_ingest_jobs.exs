defmodule Meadow.Repo.Migrations.RemovePresignedUrlIngestJobs do
  use Ecto.Migration

  def change do
    alter table(:ingest_jobs) do
      remove :presigned_url
    end
  end
end
