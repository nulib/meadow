defmodule Meadow.Repo.Migrations.CreatePlansAndPlanChanges do
  use Ecto.Migration

  def change do
    create table(:plans, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:prompt, :text, null: false)
      add(:query, :text)
      add(:status, :string, null: false, default: "pending")
      add(:user, :string)
      add(:notes, :text)
      add(:completed_at, :utc_datetime_usec)
      add(:error, :text)
      timestamps(type: :utc_datetime_usec)
    end

    create table(:plan_changes, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:plan_id, references(:plans, type: :uuid, on_delete: :delete_all), null: false)
      add(:work_id, :uuid, null: false)
      add(:changeset, :jsonb)
      add(:add, :jsonb)
      add(:delete, :jsonb)
      add(:replace, :jsonb)
      add(:status, :string, null: false, default: "pending")
      add(:user, :string)
      add(:notes, :text)
      add(:completed_at, :utc_datetime_usec)
      add(:error, :text)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:plans, [:status]))
    create(index(:plans, [:user]))
    create(index(:plans, [:inserted_at]))

    create(index(:plan_changes, [:plan_id]))
    create(index(:plan_changes, [:work_id]))
    create(index(:plan_changes, [:status]))
    create(index(:plan_changes, [:user]))
    create(index(:plan_changes, [:inserted_at]))
  end
end
