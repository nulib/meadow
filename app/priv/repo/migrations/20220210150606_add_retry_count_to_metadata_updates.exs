defmodule Meadow.Repo.Migrations.AddRetryCountToMetadataUpdates do
  use Ecto.Migration

  def change do
    alter table(:csv_metadata_update_jobs) do
      add :retries, :integer, default: 0
    end
  end
end
