defmodule Meadow.Data.FileSets.FileSetMetadata do
  @moduledoc """
  Descriptive metadata embedded in FileSet records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :location
    field :original_filename

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:location, :original_filename])
  end
end
