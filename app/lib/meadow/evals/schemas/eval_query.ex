defmodule Meadow.Evals.Schemas.EvalQuery do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_queries" do
    field(:name, :string)
    field(:description, :string)
    field(:query_json, :map)
    field(:author, :string)
    timestamps()
  end

  def changeset(eval_query, attrs) do
    eval_query
    |> cast(attrs, [:name, :description, :query_json, :author])
    |> validate_required([:name, :query_json])
    |> unique_constraint(:name)
  end
end
