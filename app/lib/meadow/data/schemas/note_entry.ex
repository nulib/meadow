defmodule Meadow.Data.Schemas.NoteEntry do
  @moduledoc """
  One note on a work (`work_notes`): free text plus a `note_type` coded term.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "work_notes" do
    belongs_to :work, Meadow.Data.Schemas.Work
    field :position, :integer
    field :note, :string
    field :type, Types.CodedTerm, scheme: "note_type", source: :type_id
  end

  def changeset(metadata, params, position \\ nil) do
    metadata
    |> cast(params, [:note, :type])
    |> put_position(position)
    |> validate_required([:note, :type])
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)

  @doc "Natural identity: `{note, type_id}`"
  def natural_key(entry) do
    type = Map.get(entry, :type) || Map.get(entry, "type")
    {Map.get(entry, :note) || Map.get(entry, "note"), coded_id(type)}
  end

  defp coded_id(%{id: id}), do: id
  defp coded_id(%{"id" => id}), do: id
  defp coded_id(id) when is_binary(id), do: id
  defp coded_id(_), do: nil

  def to_params(%__MODULE__{id: id, note: note, type: type}),
    do: %{id: id, note: note, type: type && %{id: type.id, scheme: type.scheme}}

  def to_params(%{} = map), do: map

  def from_string(""), do: nil

  def from_string(value) do
    case value |> String.split(~r/:/, parts: 2) do
      [note_type_id | [note | []]] ->
        %{type: %{id: note_type_id, scheme: "note_type"}, note: note}

      [note] ->
        %{type: %{id: "", scheme: "note_type"}, note: note}
    end
  end
end
