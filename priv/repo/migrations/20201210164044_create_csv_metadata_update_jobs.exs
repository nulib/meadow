defmodule Meadow.Repo.Migrations.CreateCSVMetadataMetadataUpdateJobs do
  use Ecto.Migration

  def change do
    create table("csv_metadata_update_jobs") do
      add(:source, :string)
      add(:rows, :integer)
      add(:errors, {:array, :map}, default: [])
      add(:status, :string)
      add(:user, :string)
      timestamps()
      add(:started_at, :utc_datetime)
    end
  end
end
