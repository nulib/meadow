defmodule Meadow.Accounts do
  @moduledoc """
  Context module for user and groups related functionality

  """

  import Ecto.Query, warn: false
  alias Meadow.Accounts
  alias Meadow.Accounts.User
  alias Meadow.Repo
  alias Ueberauth.Auth

  @doc """
  Creates a user.

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Finds or creates a user from Ueberauth auth.

  """
  def user_from_auth(
        %Auth{uid: uid, info: %Ueberauth.Auth.Info{name: name, email: email}} = _auth
      ) do
    {
      :ok,
      case Repo.get_by(User, username: uid) do
        nil ->
          {:ok, user} = Accounts.create_user(%{username: uid, display_name: name, email: email})
          %{username: user.username, display_name: user.display_name, email: user.email}

        user ->
          %{username: user.username, display_name: user.display_name, email: user.email}
      end
    }
  rescue
    e -> {:error, e}
  end
end
