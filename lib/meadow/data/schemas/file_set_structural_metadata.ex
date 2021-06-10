defmodule Meadow.Data.Schemas.FileSetStructuralMetadata do
  @moduledoc """
  Structural metadata embedded in FileSet records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :type
    field :value
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:type, :value])
  end
end
