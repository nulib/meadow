defmodule Meadow.Repo.Migrations.CreateControlledTermCache do
  use Ecto.Migration

  def change do
    create table(:controlled_term_cache, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :text

      timestamps()
    end
  end
end
