defmodule Meadow.Roles do
  @moduledoc """
  Functions for managing roles and authorizations
  """

  @doc """
  Determine if a role is authorized to perform the work of another role.

  Examples:

    iex> authorized?(:user, :any)
    true

    iex> authorized?(:superuser, :superuser)
    true

    iex> authorized?(:administrator, :superuser)
    false

    iex> authorized?(:administrator, :user)
    true

    iex> authorized?(:editor, :administrator)
    false

    iex> authorized?(:user, :user)
    true

    iex> authorized?(%{role: :user}, :user)
    true

    iex> authorized?(%{}, :user)
    false
  """
  def authorized?(%{role: role}, authorized), do: authorized?(role, authorized)

  def authorized?(nil, _), do: false
  def authorized?(_, :any), do: true
  def authorized?(:superuser, _role), do: true
  def authorized?(:administrator, :superuser), do: false
  def authorized?(:administrator, _role), do: true
  def authorized?(:manager, :editor), do: true
  def authorized?(:manager, :user), do: true
  def authorized?(:editor, :user), do: true
  def authorized?(role, role), do: true
  def authorized?(_, _), do: false
end
