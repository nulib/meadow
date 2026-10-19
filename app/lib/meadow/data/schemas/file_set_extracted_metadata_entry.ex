defmodule Meadow.Data.Schemas.FileSetExtractedMetadataEntry do
  @moduledoc """
  One node of a tool's extracted metadata document
  (`file_set_extracted_metadata_entries`). Containers (objects and arrays)
  and leaves are both rows: `path` is the list of keys from the document root
  (array indexes as strings), `value_type` is `object`, `array`, `string`,
  `integer`, `float`, `boolean` or `null`, and `value` is the leaf's text.
  `Meadow.Data.FileSets.ExtractedMetadata` flattens and rebuilds documents.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @value_types ~w(object array string integer float boolean null)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "file_set_extracted_metadata_entries" do
    belongs_to :extracted_metadata, Meadow.Data.Schemas.FileSetExtractedMetadata
    field :path, {:array, :string}
    field :value_type, :string
    field :value, :string
  end

  def value_types, do: @value_types

  def changeset(entry, params) do
    entry
    |> cast(params, [:path, :value_type, :value])
    |> validate_required([:path, :value_type])
    |> validate_inclusion(:value_type, @value_types)
  end
end
