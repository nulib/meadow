defmodule Meadow.Data.Schemas.CodedTerm do
  @moduledoc """
  CodedTerm schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "coded_terms" do
    field :id, :string, primary_key: true
    field :scheme, :string, primary_key: true
    field :label, :string

    timestamps()
  end

  @doc false
  def changeset(coded_term, attrs) do
    coded_term
    |> cast(attrs, [:scheme, :id, :label])
    |> validate_required([:scheme, :id, :label])
  end
end
