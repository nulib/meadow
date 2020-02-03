defmodule MeadowWeb.Resolvers.Accounts do
  @moduledoc """
  Absinthe resolver for User and Group Management related functionality
  """
  alias Meadow.Accounts

  def me(_, _, %{context: %{current_user: user}}) do
    {:ok, user}
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
