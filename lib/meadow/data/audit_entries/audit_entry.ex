defmodule Meadow.Data.AuditEntries.AuditEntry do
  @moduledoc """
  AuditEntries keep track of actions performed on Works and FileSets
  """
  use Ecto.Schema

  import Ecto.Changeset

  use Meadow.Constants

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "audit_entries" do
    field :object_id, Ecto.ULID
    field :action
    field :outcome
    field :notes
    timestamps()
  end

  def changeset(audit_entry, attrs \\ %{}) do
    audit_entry
    |> cast_action(attrs[:action])
    |> cast(attrs, [:object_id, :outcome, :notes])
    |> validate_required([:object_id, :action, :outcome])
  end

  defp cast_action(change, action) do
    value =
      cond do
        is_binary(action) -> action
        is_atom(action) && Code.ensure_loaded?(action) -> Module.split(action) |> Enum.join(".")
        true -> inspect(action)
      end

    Ecto.Changeset.change(change, %{action: value})
  end
end
