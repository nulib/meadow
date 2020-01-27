defmodule Meadow.Accounts do
  @moduledoc """
  Primary Context module for user and groups related functionality
  """

  defmodule User do
    @moduledoc """
    Struct for user information
    """
    defstruct [:username, :email, :display_name, :role]
  end

  alias Meadow.Accounts.Ldap

  import Ecto.Query, warn: false

  @doc "Determine if a NU user is authorized to use Meadow"
  def authorize_user_login(uid) do
    case Ldap.find_user(uid) do
      nil ->
        {:error, "Unauthorized"}

      user_entry ->
        case user_role(uid) do
          nil -> {:error, "Unauthorized"}
          role -> {:ok, %User{username: user_entry.name, email: "", display_name: "", role: role}}
        end
    end
  end

  def user_role(uid) do
    "Administrator"
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

  defp user_groups(user) do
    case Ldap.find_user(user.username) do
      %Ldap.Entry{} = entry -> Ldap.list_user_groups(entry.id) |> Enum.map(fn e -> e.name end)
      _ -> []
    end
  end
end
