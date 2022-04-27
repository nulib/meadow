defmodule Meadow.Data.Schemas.ActionState do
  @moduledoc """
  ActionStates keep track of actions performed on Works and FileSets
  """
  use Ecto.Schema
  use Meadow.Constants

  import Ecto.Changeset
  import Meadow.Utils.Atoms

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
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

  defp cast_action(change, action) do
    Ecto.Changeset.change(change, %{action: atom_to_string(action)})
  end

  defp cast_type(change, type) do
    Ecto.Changeset.change(change, %{object_type: atom_to_string(type)})
  end
end
