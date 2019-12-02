defmodule Meadow.Repo.Migrations.AddObjectTypeToAuditEntries do
  use Ecto.Migration

  def change do
    alter table(:audit_entries) do
      add :object_type, :string, null: false
    end

    create unique_index(:audit_entries, [:object_id, :action])
  end
end
