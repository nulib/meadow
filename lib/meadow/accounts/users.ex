defmodule Meadow.Accounts.Users do
  @moduledoc """
  Secondary Context module for users

  """

  import Ecto.Query, warn: false
  alias Meadow.Accounts.Schemas.User
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
          {:ok, user} = create_user(%{username: uid, display_name: name, email: email})

          %{username: user.username, display_name: user.display_name, email: user.email}

        user ->
          %{username: user.username, display_name: user.display_name, email: user.email}
      end
    }
  rescue
    e -> {:error, e}
  end
end
