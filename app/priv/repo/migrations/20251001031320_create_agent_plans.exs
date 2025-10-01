defmodule Meadow.Repo.Migrations.CreateAgentPlans do
  use Ecto.Migration

  def change do
    create table(:agent_plans) do
      add(:query, :text, null: false)
      add(:changeset, :jsonb, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:user, :string)
      add(:notes, :text)
      add(:executed_at, :utc_datetime_usec)
      add(:error, :text)
      timestamps()
    end

    create(index(:agent_plans, [:status]))
    create(index(:agent_plans, [:user]))
    create(index(:agent_plans, [:inserted_at]))
  end
end
