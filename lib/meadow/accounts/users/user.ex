defmodule Meadow.Accounts.Users.User do
  @moduledoc """
  This modeule defines the Ecto.Schema
  and Ecto.Changeset for Meadow.Accounts.Users.User

  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "users" do
    field :username, :string
    field :email, :string
    field :display_name, :string

    timestamps()

    @doc false
    def changeset(user, attrs) do
      required_fields = [:username]
      optional_fields = [:email, :display_name]

      user
      |> cast(attrs, required_fields ++ optional_fields)
      |> validate_required(required_fields)
    end
  end
end
