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

  def assume_role(user_role, current_user) do
    case(
      Cachex.get_and_update(Meadow.Cache.Users, current_user.username, fn entry ->
        Map.put(entry, :role, user_role)
      end)
    ) do
      {:commit, %{role: role}} ->
        {:ok, role}

      _ ->
        {:error, "Could not change role to #{user_role}"}
    end
  end

  def add_group_to_role(role_id, group_id) do
    Ldap.add_member(role_id, group_id)
  end
end
