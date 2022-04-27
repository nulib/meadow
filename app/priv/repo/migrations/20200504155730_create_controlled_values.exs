defmodule Meadow.Repo.Migrations.CreateControlledValues do
  use Ecto.Migration

  def change do
    create table(:controlled_values, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :string, null: false

      timestamps()
    end
  end
end
