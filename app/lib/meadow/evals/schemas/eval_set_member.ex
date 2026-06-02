defmodule Meadow.Evals.Schemas.EvalSetMember do
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Evals.Schemas.EvalSet

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_set_members" do
    field(:work_id, Ecto.UUID)
    field(:accession_number, :string)
    field(:representative_file_set_id, Ecto.UUID)
    field(:ground_truth, :map)

    belongs_to(:eval_set, EvalSet, foreign_key: :eval_set_id)

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [
      :eval_set_id,
      :work_id,
      :accession_number,
      :representative_file_set_id,
      :ground_truth
    ])
    |> validate_required([:eval_set_id, :work_id])
    |> unique_constraint([:eval_set_id, :work_id])
    |> foreign_key_constraint(:eval_set_id)
  end
end
