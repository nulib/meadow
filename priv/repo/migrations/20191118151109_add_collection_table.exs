defmodule Meadow.Repo.Migrations.AddCollectionTable do
  use Ecto.Migration

  def change do
    create table("collections") do
      add :name, :string
      add :description, :string
      add :keywords, {:array, :string}, default: []

      timestamps()
    end

    create unique_index(:collections, [:name])
  end
end
