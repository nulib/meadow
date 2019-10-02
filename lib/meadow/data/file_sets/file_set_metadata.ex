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

    timestamps()
  end

  def changeset(metadata, params) do
    required_params = [:location, :original_filename, :description]

    metadata
    |> cast(params, required_params)
    |> validate_required(required_params)
  end
end
