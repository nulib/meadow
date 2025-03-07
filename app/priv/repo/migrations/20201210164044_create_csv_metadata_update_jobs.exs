defmodule Meadow.Repo.Migrations.CreateCSVMetadataMetadataUpdateJobs do
  use Ecto.Migration

  def change do
    create table(:csv_metadata_update_jobs) do
      add(:filename, :string)
      add(:source, :string)
      add(:rows, :integer)
      add(:errors, {:array, :map}, default: [])
      add(:status, :string)
      add(:user, :string)
      add(:started_at, :utc_datetime)
      add(:active, :boolean)
      add(:retries, :integer, default: 0)
      timestamps()
    end

    create(unique_index(:csv_metadata_update_jobs, [:active], where: "active=true"))
  end
end
