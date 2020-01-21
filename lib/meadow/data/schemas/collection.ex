defmodule Meadow.Data.Schemas.Collection do
  @moduledoc """
  Collections are used to group objects for display
  """
  use Ecto.Schema
  use Meadow.Constants

  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "collections" do
    field :name, :string
    field :description, :string
    field :keywords, {:array, :string}, default: []
    field :featured, :boolean
    field :finding_aid_url, :string
    field :admin_email, :string

    timestamps()

    has_many :works, Work
  end

  def changeset(collection, params) do
    collection
    |> cast(params, [:name, :description, :keywords, :featured, :finding_aid_url, :admin_email])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
