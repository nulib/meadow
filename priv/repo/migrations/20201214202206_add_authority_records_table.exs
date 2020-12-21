defmodule Meadow.Repo.Migrations.AddAuthorityRecordsTable do
  use Ecto.Migration

  def change do
    create table(:authority_records, primary_key: false) do
      add :id, :string, primary_key: true
      add :label, :string, null: false
      add :hint, :string

      timestamps()
    end

    create(index(:authority_records, ["lower(label)"]))
    create(index(:authority_records, [:inserted_at, :id]))
  end
end
