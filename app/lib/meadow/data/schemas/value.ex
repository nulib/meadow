defmodule Meadow.Data.Schemas.ControlledValue do
  @moduledoc """
  ControlledValue schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "controlled_values" do
    field :label, :string

    timestamps()
  end

  @doc false
  def changeset(controlled_value, attrs) do
    controlled_value
    |> cast(attrs, [:id, :label])
    |> validate_required([:id, :label])
  end
end
