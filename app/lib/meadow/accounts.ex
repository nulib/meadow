defmodule Meadow.Accounts do
  @moduledoc """
  Primary Context module for user and groups related functionality
  """

  alias Meadow.Accounts.Schemas.User, as: UserSchema
  alias Meadow.Accounts.User
  alias Meadow.Repo

  import Ecto.Query, warn: false

  @doc "Determine if a NU user is authorized to use Meadow"
  def authorize_user_login(net_id) when is_binary(net_id) do
    User.find(net_id)
    |> handle_user_response()
  end

  def authorize_user_login(user_info) do
    User.validate(user_info)
    |> handle_user_response()
  end

  defp handle_user_response(nil), do: {:error, "Unauthorized"}
  defp handle_user_response(%User{role: nil}), do: {:error, "Unauthorized"}
  defp handle_user_response(%User{} = user), do: {:ok, user}

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
