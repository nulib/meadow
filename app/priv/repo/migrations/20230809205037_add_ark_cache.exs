defmodule Meadow.Repo.Migrations.AddArkCache do
  use Ecto.Migration

  def change do
    create table(:ark_cache, primary_key: [name: :ark, type: :string]) do
      add(:creator, :string)
      add(:title, :string)
      add(:publisher, :string)
      add(:publication_year, :string)
      add(:resource_type, :string)
      add(:status, :string)
      add(:target, :string)
      add(:work_id, :binary_id)
    end

    create index(:ark_cache, [:work_id], concurrently: false)
  end
end
