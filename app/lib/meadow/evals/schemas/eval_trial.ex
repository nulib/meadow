defmodule Meadow.Evals.Schemas.EvalTrial do
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Evals.Schemas.{EvalRun, EvalTrialScore}

  @trial_statuses [:pending, :running, :complete, :errored, :skipped]

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_trials" do
    field(:work_id, Ecto.UUID)
    field(:trial_index, :integer)
    field(:status, Ecto.Enum, values: @trial_statuses, default: :pending)
    field(:agent_output, :map)
    field(:transcript, :map)
    field(:description_judge_score, :float)
    field(:subjects_judge_score, :float)
    field(:judge_rationale, :string)
    field(:error, :string)
    field(:duration_ms, :integer)

    belongs_to(:eval_run, EvalRun, foreign_key: :eval_run_id)
    has_many(:scores, EvalTrialScore, foreign_key: :eval_trial_id)

    timestamps()
  end

  def changeset(trial, attrs) do
    trial
    |> cast(attrs, [:eval_run_id, :work_id, :trial_index, :status])
    |> validate_required([:eval_run_id, :work_id, :trial_index])
    |> foreign_key_constraint(:eval_run_id)
  end

  def mark_running(trial) do
    trial |> cast(%{status: :running}, [:status])
  end

  def mark_complete(trial, attrs) do
    trial
    |> cast(
      Map.merge(attrs, %{status: :complete}),
      [
        :status,
        :agent_output,
        :transcript,
        :description_judge_score,
        :subjects_judge_score,
        :judge_rationale,
        :duration_ms
      ]
    )
  end

  def mark_errored(trial, error) do
    trial |> cast(%{status: :errored, error: error}, [:status, :error])
  end
end
