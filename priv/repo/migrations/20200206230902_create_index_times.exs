defmodule Meadow.Repo.Migrations.AddIndexTimes do
  use Ecto.Migration

  def change do
    create table(:index_times, primary_key: false) do
      add(:id, :binary_id, primary_key: true, null: false)
      add(:indexed_at, :utc_datetime_usec, null: false)
    end
  end
end
