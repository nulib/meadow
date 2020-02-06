defmodule Meadow.Accounts.User do
  @moduledoc """
  Struct for user information
  """
  use Meadow.Constants
  alias Meadow.Accounts.Ldap

  defstruct [:id, :username, :email, :display_name, :role]

  @doc "Find a user by username and populate the User struct"
  def find(username) do
    case Ldap.find_user(username) do
      nil ->
        nil

      user_entry ->
        %__MODULE__{
          id: user_entry.id,
          username: user_entry.attributes.uid,
          email: user_entry.attributes.mail,
          display_name: user_entry.attributes.displayName,
          role: user_role(user_entry)
        }
    end
  end

  defp user_role(user_entry) do
    with groups <- user_groups(user_entry) do
      case Enum.find(@role_priority, fn group -> groups |> Enum.member?(group) end) do
        nil -> nil
        val -> Inflex.Pluralize.singularize(val)
      end
    end
  end

  defp user_groups(user_entry) do
    case user_entry do
      %Ldap.Entry{} = entry -> Ldap.list_user_groups(entry.id) |> Enum.map(fn e -> e.name end)
      _ -> []
    end
  end
end
