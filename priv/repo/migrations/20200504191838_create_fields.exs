defmodule Meadow.Repo.Migrations.CreateFields do
  use Ecto.Migration

  def change do
    create table(:fields, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :string
      add :repeating, :boolean, default: false, null: false
      add :required, :boolean, default: false, null: false
      add :metadata_class, :string

      timestamps()
    end
  end
end
