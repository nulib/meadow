defmodule Meadow.Roles do
  @moduledoc """
  Functions for managing roles and authorizations
  """

  @doc """
  Determine if a role is authorized to perform the work of another role.

  Examples:

    iex> authorized?("User", :any)
    true

    iex> authorized?("SuperUser", "SuperUser")
    true

    iex> authorized?("Administrator", "SuperUser")
    false

    iex> authorized?("Administrator", "User")
    true

    iex> authorized?("Editor", "Administrator")
    false

    iex> authorized?("User", "User")
    true

    iex> authorized?(%{role: "User"}, "User")
    true

    iex> authorized?(%{}, "User")
    false
  """
  def authorized?(%{role: role}, authorized), do: authorized?(role, authorized)

  def authorized?(nil, _), do: false
  def authorized?(_, :any), do: true
  def authorized?("SuperUser", _role), do: true
  def authorized?("Administrator", "SuperUser"), do: false
  def authorized?("Administrator", _role), do: true
  def authorized?("Manager", "Editor"), do: true
  def authorized?("Manager", "User"), do: true
  def authorized?("Editor", "User"), do: true
  def authorized?(role, role), do: true
  def authorized?(_, _), do: false
end
