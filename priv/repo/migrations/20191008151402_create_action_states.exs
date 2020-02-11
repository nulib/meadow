defmodule Meadow.Repo.Migrations.CreateActionStates do
  use Ecto.Migration

  def change do
    create table(:action_states) do
      add(:object_id, :binary_id, null: false)
      add(:object_type, :string, null: false)
      add(:action, :string, null: false)
      add(:outcome, :string, null: false)
      add(:notes, :text)
      timestamps()
    end

    create(unique_index(:action_states, [:object_id, :action]))
  end
end
