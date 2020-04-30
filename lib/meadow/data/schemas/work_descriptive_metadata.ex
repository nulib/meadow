defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    field :description, :string
    field :keywords, {:array, :string}, default: []
    field :nul_subject, {:array, :string}, default: []
    field :title, {:array, :string}, default: []

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :description,
      :keywords,
      :nul_subject,
      :title
    ])
  end
end
