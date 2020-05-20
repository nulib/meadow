defmodule Meadow.Data.Schemas.ControlledMetadataEntry do
  @moduledoc """
  ControlledMetadataEntry schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @schemes %{
    "contributor" => "marc_relator",
    "subject" => "subject_role"
  }

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  schema "controlled_metadata_entries" do
    field :object_id, Ecto.UUID
    field :role_id, :string
    field :field_id, :string
    field :value_id, Meadow.Data.Types.ControlledTerm

    timestamps()
  end

  @doc false
  def changeset(controlled_metadata_entry, attrs) do
    required_params = [:value_id, :field_id]

    controlled_metadata_entry
    |> cast(attrs, [:value_id, :field_id, :role_id])
    |> validate_required(required_params)
  end

  def scheme_for(field) do
    @schemes
    |> Map.get(field)
  end
end
