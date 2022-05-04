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

    token = conn |> Map.get(:req_cookies, %{}) |> Map.get("_meadow_key", "")

    case refresh_user(user) do
      user = %User{} ->
        conn
        |> Absinthe.Plug.put_options(context: %{auth_token: token, current_user: user})
        |> Plug.Conn.assign(:current_user, user)

      nil ->
        conn
        |> Absinthe.Plug.put_options(context: %{})
        |> Plug.Conn.assign(:current_user, nil)
    end
  end

  defp refresh_user(%{username: username}) do
    case Accounts.authorize_user_login(username) do
      {:ok, user} ->
        user

      _ ->
        nil
    end
  end

  defp refresh_user(_), do: nil
end
