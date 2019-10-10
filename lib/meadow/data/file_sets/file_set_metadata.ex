defmodule Meadow.Data.FileSets.FileSetMetadata do
  @moduledoc """
  Descriptive metadata embedded in FileSet records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :location
    field :original_filename
    field :description
    field :digests, :map

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:location, :digests, :original_filename, :description])
    |> validate_required([:location, :original_filename])
  end
end
