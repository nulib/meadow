defmodule Meadow.Data.Schemas.ControlledMetadataEntry do
  @moduledoc """
  ControlledMetadataEntry schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  schema "controlled_metadata_entries" do
    field :object_id, Ecto.UUID
    field :role_id, :string
    field :field_id, :string
    field :value_id, :string

    timestamps()
  end

  @doc false
  def changeset(controlled_metadata_entry, attrs) do
    controlled_metadata_entry
    |> cast(attrs, [:object_id, :role_id])
  end
end
