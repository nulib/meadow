defmodule Meadow.Data.Schemas.Field do
  @moduledoc """
  Field schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import EctoEnum

  defenum(MetadataClassEnum,
    administrative: "administrative",
    core: "core",
    descriptive: "descriptive"
  )

  @primary_key {:id, :string, autogenerate: false}
  schema "fields" do
    field :label, :string
    field :repeating, :boolean, default: false
    field :required, :boolean, default: false
    field :role, :string
    field :scheme, :string
    field :metadata_class, MetadataClassEnum

    timestamps()
  end

  @doc false
  def changeset(field, attrs) do
    field
    |> cast(attrs, [:id, :label, :metadata_class, :repeating, :required])
    |> validate_required([:id, :label, :metadata_class])
  end
end
