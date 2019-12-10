defmodule Meadow.Data.Works.WorkMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :title
    field :description

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:title, :description])
  end
end
