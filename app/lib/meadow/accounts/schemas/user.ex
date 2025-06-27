defmodule Meadow.Accounts.Schemas.User do
  @moduledoc """
  Schema for Meadow User
  """
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :string, autogenerate: false}
  @roles [
    superuser: "Superuser",
    administrator: "Administrator",
    manager: "Manager",
    editor: "Editor",
    user: "User"
  ]

  schema "users" do
    field :role, Ecto.Enum, values: @roles, default: :user
    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:id, :role])
    |> validate_required([:id, :role])
    |> unique_constraint(:id, name: :users_pkey)
  end

  @doc """
  List all roles available in the system.
  """
  def list_roles do
    @roles |> Keyword.values()
  end
end
