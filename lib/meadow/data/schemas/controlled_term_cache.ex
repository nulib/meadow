defmodule Meadow.Data.Schemas.ControlledTermCache do
  @moduledoc """
  Schema for Controlled Term Cache
  """
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :string, autogenerate: false}

  schema "controlled_term_cache" do
    field :label, :string
    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:id, :label])
    |> validate_required([:id, :label])
  end
end
