defmodule MeadowWeb.Resolvers.Accounts do
  @moduledoc """
  Absinthe resolver for User and Group Management related functionality
  """

  alias Meadow.Accounts.Ldap

  def me(_, _, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def me(_, _, _) do
    {:ok, nil}
  end

  def list_groups(_, _, _) do
    {:ok, Ldap.list_groups()}
  end

  def user_groups(_, %{username: name}, _) do
    {:ok,
     Ldap.list_user_groups(name)
     |> Enum.map(fn e -> %{name: e.name} end)}
  end

  def group_members(_, %{group_name: name}, _) do
    {:ok,
     Ldap.list_group_members(name)
     |> Enum.map(fn e -> %{username: e.name} end)}
  end
end
