defmodule MeadowWeb.Resolvers.Accounts do
  @moduledoc """
  Absinthe resolver for User and Group Management related functionality
  """
  alias Meadow.Accounts

  def me(_, _, %{context: %{auth_token: token, current_user: user}}) do
    {:ok, Map.put(user, :token, token)}
  end

  def me(_, _, _) do
    {:ok, nil}
  end

  def list_roles(_, _, _) do
    {:ok, Accounts.list_roles()}
  end

  def role_members(_, %{id: id}, _) do
    {:ok, Accounts.role_members(id)}
  end

  def group_members(_, %{id: id}, _) do
    {:ok, Accounts.group_members(id)}
  end

  def assume_role(_, %{user_role: user_role}, %{context: %{current_user: user}}) do
    case Accounts.assume_role(user_role, user) do
      {:ok, role} ->
        {:ok, %{message: "Role changed to: #{role}"}}

      {:error, error} ->
        {:error, %{message: error}}
    end
  end

  def add_group_to_role(_, %{group_id: group_id, role_id: role_id}, _) do
    {:ok,
     case Accounts.add_group_to_role(role_id, group_id) do
       :ok ->
         %{message: "OK"}

       :exists ->
         %{message: "EXISTS"}

       other ->
         %{message: other}
     end}
  end
end
