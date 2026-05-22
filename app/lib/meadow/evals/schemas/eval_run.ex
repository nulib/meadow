defmodule Meadow.Evals.Schemas.EvalRun do
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Evals.Schemas.{EvalPromptVersion, EvalSet, EvalTrial}

  @statuses [:pending, :running, :complete, :errored, :cancelled]

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_runs" do
    field(:name, :string)
    field(:trials_per_work, :integer, default: 1)
    field(:concurrency, :integer, default: 3)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:started_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:author, :string)
    field(:error, :string)

    belongs_to(:eval_set, EvalSet, foreign_key: :eval_set_id)

    belongs_to(:prompt_version, EvalPromptVersion,
      foreign_key: :prompt_version_id,
      references: :id
    )

    has_many(:eval_trials, EvalTrial, foreign_key: :eval_run_id)

    timestamps()
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :name,
      :eval_set_id,
      :prompt_version_id,
      :trials_per_work,
      :concurrency,
      :author
    ])
    |> validate_required([:eval_set_id, :prompt_version_id])
    |> validate_number(:trials_per_work, greater_than: 0)
    |> validate_number(:concurrency, greater_than: 0)
    |> foreign_key_constraint(:eval_set_id)
    |> foreign_key_constraint(:prompt_version_id)
  end

  def mark_running(run) do
    run
    |> cast(%{status: :running, started_at: DateTime.utc_now()}, [:status, :started_at])
  end

  def mark_complete(run) do
    run
    |> cast(%{status: :complete, completed_at: DateTime.utc_now()}, [:status, :completed_at])
  end

  def mark_errored(run, error) do
    run
    |> cast(%{status: :errored, error: error, completed_at: DateTime.utc_now()},
      [:status, :error, :completed_at])
  end

  def mark_cancelled(run) do
    run
    |> cast(%{status: :cancelled, completed_at: DateTime.utc_now()}, [:status, :completed_at])
  end
end
