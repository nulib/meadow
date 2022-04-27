defmodule Meadow.Data.Schemas.NoteEntry do
  @moduledoc """
  Schema for Note
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key false
  embedded_schema do
    field :note, :string
    field :type, Types.CodedTerm
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:note, :type])
    |> validate_required([:note, :type])
  end

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
