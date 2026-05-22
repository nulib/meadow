defmodule Meadow.Repo.Migrations.CreateEvals do
  use Ecto.Migration

  def change do
    create table(:eval_queries, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :string, null: false)
      add(:description, :text)
      add(:query_json, :jsonb, null: false)
      add(:author, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:eval_queries, [:name]))

    create table(:eval_prompt_versions, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :string, null: false)
      add(:system_prompt, :text, null: false)
      add(:user_prompt_template, :text, null: false)
      add(:subject_prompt, :text)
      add(:description_prompt, :text)

      add(
        :parent_version_id,
        references(:eval_prompt_versions, type: :uuid, on_delete: :nilify_all)
      )

      add(:author, :string)
      add(:change_notes, :text)
      add(:archived, :boolean, default: false, null: false)
      timestamps(type: :utc_datetime_usec)
    end

    create table(:eval_sets, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :string, null: false)
      add(:description, :text)

      add(:query_id, references(:eval_queries, type: :uuid, on_delete: :nilify_all))

      add(:query_snapshot, :jsonb)
      add(:work_count, :integer)
      add(:author, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create table(:eval_set_members, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:eval_set_id, references(:eval_sets, type: :uuid, on_delete: :delete_all), null: false)

      add(:work_id, :uuid, null: false)
      add(:accession_number, :string)
      add(:representative_file_set_id, :uuid)
      add(:ground_truth, :jsonb)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:eval_set_members, [:eval_set_id, :work_id]))
    create(index(:eval_set_members, [:eval_set_id]))

    create table(:eval_runs, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :string)

      add(:eval_set_id, references(:eval_sets, type: :uuid, on_delete: :restrict), null: false)

      add(
        :prompt_version_id,
        references(:eval_prompt_versions, type: :uuid, on_delete: :restrict),
        null: false
      )

      add(:trials_per_work, :integer, null: false, default: 1)
      add(:concurrency, :integer, default: 3)
      add(:status, :string, null: false, default: "pending")
      add(:started_at, :utc_datetime_usec)
      add(:completed_at, :utc_datetime_usec)
      add(:author, :string)
      add(:error, :text)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:eval_runs, [:status]))
    create(index(:eval_runs, [:eval_set_id]))

    create table(:eval_trials, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:eval_run_id, references(:eval_runs, type: :uuid, on_delete: :delete_all), null: false)

      add(:work_id, :uuid, null: false)
      add(:trial_index, :integer, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:agent_output, :jsonb)
      add(:transcript, :jsonb)
      add(:description_judge_score, :float)
      add(:subjects_judge_score, :float)
      add(:judge_rationale, :text)
      add(:manual_score, :string, default: "unscored")
      add(:manual_notes, :text)
      add(:manual_scored_by, :string)
      add(:manual_scored_at, :utc_datetime_usec)
      add(:error, :text)
      add(:duration_ms, :integer)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:eval_trials, [:eval_run_id, :work_id, :trial_index]))
    create(index(:eval_trials, [:eval_run_id, :status]))
  end
end
