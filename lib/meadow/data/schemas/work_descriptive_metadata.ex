defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :description, :string
    field :genre, {:array, :string}, default: []
    field :keywords, {:array, :string}, default: []
    field :nul_subject, {:array, :string}, default: []
    field :technique, :string
    field :title, :string

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :description,
      :genre,
      :keywords,
      :nul_subject,
      :technique,
      :title
    ])
  end
end
