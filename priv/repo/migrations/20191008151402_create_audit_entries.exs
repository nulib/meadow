defmodule Meadow.Repo.Migrations.CreateAuditEntries do
  use Ecto.Migration

  def change do
    create table(:audit_entries) do
      add :object_id, :binary_id, null: false
      add :action, :string, null: false
      add :outcome, :string, null: false
      add :notes, :text
      timestamps()
    end
  end
end
