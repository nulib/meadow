defmodule Meadow.Accounts do
  @moduledoc """
  Primary Context module for user and groups related functionality
  """

  alias Meadow.Accounts.{Ldap, User}

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
    Ldap.list_groups()
  end

  def role_members(id) do
    Ldap.list_group_members(id)
  end

  def group_members(id) do
    Ldap.list_group_members(id)
  end

  def add_group_to_role(group_id, role_id) do
    Ldap.add_member(group_id, role_id)
  end
end
