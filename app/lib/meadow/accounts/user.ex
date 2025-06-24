defmodule Meadow.Accounts.User do
  @moduledoc """
  Struct for user information
  """
  alias Meadow.Accounts
  alias Meadow.Accounts.Directory

  use Meadow.Constants
  require Logger

  defstruct [:id, :username, :email, :display_name, :role]

  @doc "Find a user by username and populate the User struct"
  def find(username) do
    case Directory.find_user(username) do
      {:error, error} ->
        Logger.error("Error fetching user #{username}: #{error}")
        nil

      nil ->
        nil

      user_entry ->
        case user_role(user_entry) do
          :none ->
            nil

          role ->
            make_struct(user_entry, role)
        end
    end
  end

  defp make_struct(user_entry, role) do
    net_id = Map.get(user_entry, "uid")

    %__MODULE__{
      id: net_id,
      username: net_id,
      email: Map.get(user_entry, "mail"),
      display_name: Map.get(user_entry, "nuAllDisplayName"),
      role: role
    }
  end

  defp user_role(%{"uid" => net_id, "nuAllSchoolAffiliations" => affiliations}) do
    is_lib_staff = Enum.member?(affiliations, "lib:staff")

    case {is_lib_staff, Accounts.get_role(net_id)} do
      {true, nil} -> :user
      {_, nil} -> :none
      {_, role} -> role
    end
  end
end
