defmodule Meadow.Accounts do
  @moduledoc """
  Primary Context module for user and groups related functionality
  """

  alias Meadow.Accounts.Schemas.User, as: UserSchema
  alias Meadow.Accounts.User
  alias Meadow.Repo

  import Ecto.Query, warn: false

  @doc "Determine if a NU user is authorized to use Meadow"
  def authorize_user_login(username) do
    case User.find(username) do
      nil ->
        {:error, "Unauthorized"}

      user ->
        case user.role do
          nil -> {:error, "Unauthorized"}
          _ -> {:ok, user}
        end
    end
  end

  def list_roles do
    UserSchema.list_roles()
  end

  def role_members(role) do
    from(u in UserSchema, where: u.role == ^role)
    |> Repo.all()
  end

  def list_users do
    from(u in UserSchema, order_by: [asc: u.id])
    |> Repo.all()
  end

  def get_role(net_id) do
    from(u in UserSchema, where: u.id == ^net_id, select: u.role)
    |> Repo.one()
  end

  def set_user_role(user_id, user_role) do
    case Repo.get(UserSchema, user_id) |> _set_user_role(%{id: user_id, role: user_role}) do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end

  defp _set_user_role(nil, attrs) do
    UserSchema.changeset(%UserSchema{}, attrs)
    |> Repo.insert()
  end

  defp _set_user_role(%UserSchema{} = user, %{role: nil}) do
    Repo.delete(user)
  end

  defp _set_user_role(%UserSchema{} = user, %{role: role}) do
    UserSchema.changeset(user, %{role: role})
    |> Repo.update()
  end
end
