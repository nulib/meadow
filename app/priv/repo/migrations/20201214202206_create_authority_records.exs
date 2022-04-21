defmodule Meadow.Repo.Migrations.CreateAuthorityRecords do
  use Ecto.Migration

  def change do
    create table(:authority_records, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :string, null: false
      add :hint, :string

      timestamps()
    end

    create(unique_index(:authority_records, [:label]))
    create(index(:authority_records, ["lower(label)"]))
    create(index(:authority_records, [:inserted_at, :id]))
  end
end
