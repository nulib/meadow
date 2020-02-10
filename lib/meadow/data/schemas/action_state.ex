defmodule Meadow.Data.Schemas.ActionState do
  @moduledoc """
  ActionStates keep track of actions performed on Works and FileSets
  """
  use Ecto.Schema

  import Ecto.Changeset

  use Meadow.Constants

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "action_states" do
    field :object_type
    field :object_id, Ecto.UUID
    field :action
    field :outcome
    field :notes
    timestamps()
  end

  def changeset(action_state, attrs \\ %{}) do
    action_state
    |> cast_action(attrs[:action])
    |> cast_type(attrs[:object_type])
    |> cast(attrs, [:object_id, :outcome, :notes])
    |> validate_required([:object_id, :action, :outcome])
  end

  def atom_to_string(action) do
    cond do
      is_binary(action) -> action
      is_atom(action) && Code.ensure_loaded?(action) -> Module.split(action) |> Enum.join(".")
      true -> inspect(action)
    end
  end

  defp cast_action(change, action) do
    Ecto.Changeset.change(change, %{action: atom_to_string(action)})
  end

  defp cast_type(change, type) do
    Ecto.Changeset.change(change, %{object_type: atom_to_string(type)})
  end
end
