defmodule Meadow.Data.Schemas.MetadataValue do
  @moduledoc """
  One value of a repeating free-text metadata field on a work
  (`work_metadata_values`). `section` is `"descriptive"` or `"administrative"`,
  `field` is the metadata field name, and `position` is the value's place in the
  field's list. Each value has a stable id so edits, reorders and provenance can
  refer to it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @sections ~w(descriptive administrative)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "work_metadata_values" do
    belongs_to :work, Meadow.Data.Schemas.Work
    field :section, :string
    field :field, :string
    field :position, :integer
    field :value, :string
  end

  def sections, do: @sections

  @doc "Changeset for one value; `position` is the item's index in the incoming list"
  def changeset(entry, params, position) do
    entry
    |> cast(params, [:value])
    |> put_change(:position, position)
    |> validate_required([:value])
  end

  @doc "The plain string values of a list of entries (public, flat shape)"
  def values(entries) when is_list(entries), do: Enum.map(entries, &value/1)
  def values(_), do: []

  def value(%__MODULE__{value: value}), do: value
  def value(%{value: value}), do: value
  def value(%{"value" => value}), do: value
  def value(value) when is_binary(value), do: value
  def value(_), do: nil

  @doc "Normalize an incoming item (bare string or map) into entry params"
  def to_params(value) when is_binary(value), do: %{value: value}
  def to_params(%__MODULE__{id: id, value: value}), do: %{id: id, value: value}
  def to_params(%{} = map), do: map
  def to_params(nil), do: nil
end
