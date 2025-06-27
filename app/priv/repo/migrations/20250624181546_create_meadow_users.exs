defmodule Meadow.Repo.Migrations.CreateMeadowUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:role, :string)
      timestamps()
    end
  end
end
