defmodule Meadow.Evals.Schemas.EvalTrialScore do
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Evals.Schemas.EvalTrial

  @scores [:good, :bad]

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_trial_scores" do
    field(:scored_by, :string)
    field(:score, Ecto.Enum, values: @scores)
    field(:notes, :string)
    field(:scored_at, :utc_datetime_usec)

    belongs_to(:eval_trial, EvalTrial, foreign_key: :eval_trial_id)

    timestamps()
  end

  def changeset(score, attrs) do
    score
    |> cast(attrs, [:eval_trial_id, :scored_by, :score, :notes, :scored_at])
    |> validate_required([:eval_trial_id, :scored_by, :score])
    |> validate_inclusion(:score, @scores)
    |> foreign_key_constraint(:eval_trial_id)
    |> unique_constraint([:eval_trial_id, :scored_by])
  end
end
