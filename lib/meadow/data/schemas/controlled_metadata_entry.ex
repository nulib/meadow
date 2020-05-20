defmodule Meadow.Data.Schemas.ControlledMetadataEntry do
  @moduledoc """
  Schema for Controlled Entry with Role qualifier
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key false
  embedded_schema do
    field :role, Types.CodedTerm
    field :term, Types.ControlledTerm
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:role, :term])
    |> validate_required([:term])
  end
end
