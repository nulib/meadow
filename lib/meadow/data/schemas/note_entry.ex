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
    [note_type_id | [note | []]] = value |> String.split(~r/:/, parts: 2)
    %{type: %{id: note_type_id, scheme: "note_type"}, note: note}
  end
end
