defmodule Meadow.Repo.Migrations.RenameAuditEntriesToActionStates do
  use Ecto.Migration

  def change do
    rename table("audit_entries"), to: table("action_states")
  end
end
