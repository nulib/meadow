defmodule Meadow.Data.Schemas.FileSetCoreMetadata do
  @moduledoc """
  Descriptive metadata embedded in FileSet records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    field :location
    field :original_filename
    field :description
    field :label
    field :alt_text
    field :digests, :map
    field :image_caption
    field :mime_type

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :alt_text,
      :description,
      :digests,
      :image_caption,
      :label,
      :location,
      :mime_type,
      :original_filename
    ])
    |> validate_required([:location, :original_filename])
  end
end
