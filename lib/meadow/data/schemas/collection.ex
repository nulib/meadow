defmodule Meadow.Data.Schemas.Collection do
  @moduledoc """
  Collections are used to group objects for display
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work

  use Meadow.Constants

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "collections" do
    field :name, :string
    field :description, :string
    field :keywords, {:array, :string}, default: []

    timestamps()

    many_to_many :works, Work, join_through: "collections_works", on_replace: :delete
  end

  def changeset(collection, params) do
    collection
    |> cast(params, [:name, :description, :keywords])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
