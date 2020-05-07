defmodule Meadow.Repo.Migrations.CreateControlledMetadataEntries do
  use Ecto.Migration

  def change do
    create table(:controlled_metadata_entries) do
      add :object_id, :binary_id
      add :field_id, :string
      add :role_id, :string
      add :value_id, :string

      timestamps()
    end
  end
end
