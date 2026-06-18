defmodule Meadow.Repo.Migrations.CreateEvalTrialScores do
  use Ecto.Migration

  def up do
    create table(:eval_trial_scores, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:eval_trial_id, references(:eval_trials, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:scored_by, :string, null: false)
      add(:score, :string, null: false)
      add(:notes, :text)
      add(:scored_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:eval_trial_scores, [:eval_trial_id, :scored_by]))
    create(index(:eval_trial_scores, [:eval_trial_id]))

    # Copy existing single-valued manual scores into the new per-user table.
    execute("""
    INSERT INTO eval_trial_scores
      (id, eval_trial_id, scored_by, score, notes, scored_at, inserted_at, updated_at)
    SELECT
      gen_random_uuid(),
      id,
      COALESCE(manual_scored_by, 'unknown'),
      manual_score,
      manual_notes,
      COALESCE(manual_scored_at, now()),
      now(),
      now()
    FROM eval_trials
    WHERE manual_score IS NOT NULL AND manual_score <> 'unscored'
    """)

    alter table(:eval_trials) do
      remove(:manual_score)
      remove(:manual_notes)
      remove(:manual_scored_by)
      remove(:manual_scored_at)
    end
  end

  def down do
    alter table(:eval_trials) do
      add(:manual_score, :string, default: "unscored")
      add(:manual_notes, :text)
      add(:manual_scored_by, :string)
      add(:manual_scored_at, :utc_datetime_usec)
    end

    # Restore the most recent score per trial back onto the trial row.
    execute("""
    UPDATE eval_trials t
    SET manual_score = s.score,
        manual_notes = s.notes,
        manual_scored_by = s.scored_by,
        manual_scored_at = s.scored_at
    FROM (
      SELECT DISTINCT ON (eval_trial_id)
        eval_trial_id, score, notes, scored_by, scored_at
      FROM eval_trial_scores
      ORDER BY eval_trial_id, scored_at DESC
    ) s
    WHERE t.id = s.eval_trial_id
    """)

    drop(table(:eval_trial_scores))
  end
end
