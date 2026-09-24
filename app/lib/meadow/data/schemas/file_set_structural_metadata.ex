defmodule Meadow.Data.Schemas.FileSetStructuralMetadata do
  @moduledoc """
  Structural metadata for a FileSet (`file_set_structural_metadata`, at most
  one row per file set), e.g. a WebVTT document.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  @foreign_key_type Ecto.UUID
  schema "file_set_structural_metadata" do
    belongs_to :file_set, Meadow.Data.Schemas.FileSet, primary_key: true
    field :type, :string
    field :value, :string
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:type, :value])
  end
end
