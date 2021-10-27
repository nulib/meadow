defmodule Meadow.Repo.Migrations.CreateWorksMetadataUpdateJobs do
  use Ecto.Migration

  def change do
    create table(:works_metadata_update_jobs, primary_key: false) do
      add :metadata_update_job_id, references(:csv_metadata_update_jobs, on_delete: :delete_all), null: false, primary_key: true
      add :work_id, references(:works, on_delete: :delete_all), null: false, primary_key: true
    end
  end
end
