defmodule MeadowWeb.Plugs.SetCurrentUser do
  @moduledoc """
  Checks for current user in the session. Refreshes the user and then puts the current user in `conn.assigns["current_user"]` and in the Absinthe context
  """
  @behaviour Plug
  alias Meadow.Accounts
  alias Meadow.Accounts.User
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    user =
      conn
      |> fetch_session
      |> get_session(:current_user)

    case refresh_user(user) do
      user = %User{} ->
        conn
        |> Absinthe.Plug.put_options(context: %{current_user: user})
        |> Plug.Conn.assign(:current_user, user)

      nil ->
        conn
        |> Absinthe.Plug.put_options(context: %{})
        |> Plug.Conn.assign(:current_user, nil)
    end
  end

  defp refresh_user(%{username: username}) do
    case Cachex.get!(Meadow.Cache.Users, username) do
      nil ->
        refresh_user_ldap(username)

      user ->
        user
    end
  end

  defp refresh_user(_), do: nil

  defp refresh_user_ldap(username) do
    case Accounts.authorize_user_login(username) do
      {:ok, user} ->
        user

      _ ->
        nil
    end
  end
end
