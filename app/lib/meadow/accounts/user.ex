defmodule Meadow.Accounts.User do
  @moduledoc """
  Struct for user information
  """
  use Meadow.Constants
  alias Meadow.Accounts.Ldap
  require Logger

  defstruct [:id, :username, :email, :display_name, :role]

  @doc "Find a user by username and populate the User struct"
  def find(username) do
    {status, result} =
      Cachex.fetch(Meadow.Cache.Users, username, fn _key ->
        case Ldap.find_user(username) do
          nil -> {:ignore, nil}
          user_entry -> {:commit, make_struct(user_entry)}
        end
      end)

    case status do
      :ok -> Logger.debug("User #{username} found in cache")
      :commit -> Logger.debug("User #{username} found in LDAP and added to cache")
      :error -> Logger.error("Error trying to retrieve user #{username}: #{result}")
      :ignore -> Logger.warn("User #{username} not found")
    end

    result
  end

  defp make_struct(user_entry) do
    %__MODULE__{
      id: user_entry.id,
      username: user_entry.name,
      email: user_entry.attributes.mail,
      display_name: user_entry.attributes.displayName,
      role: user_role(user_entry)
    }
  end

  defp user_role(user_entry) do
    with groups <- user_groups(user_entry) do
      case Enum.find(@role_priority, fn group -> groups |> Enum.member?(group) end) do
        nil -> nil
        val -> Inflex.Pluralize.singularize(val)
      end
    end
  end

  defp user_groups(%Ldap.Entry{} = user_entry) do
    Ldap.list_user_groups(user_entry.id) |> Enum.map(fn e -> e.name end)
  end
end
