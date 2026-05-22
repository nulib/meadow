defmodule Meadow.Evals.Schemas.EvalSet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Evals.Schemas.{EvalQuery, EvalSetMember}

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_sets" do
    field(:name, :string)
    field(:description, :string)
    field(:query_snapshot, :map)
    field(:work_count, :integer)
    field(:author, :string)

    belongs_to(:eval_query, EvalQuery, foreign_key: :query_id)
    has_many(:eval_set_members, EvalSetMember, foreign_key: :eval_set_id)

    timestamps()
  end

  def changeset(eval_set, attrs) do
    eval_set
    |> cast(attrs, [:name, :description, :query_id, :query_snapshot, :work_count, :author])
    |> validate_required([:name])
    |> foreign_key_constraint(:query_id)
  end
end
