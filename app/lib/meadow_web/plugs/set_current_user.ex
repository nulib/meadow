defmodule MeadowWeb.Plugs.SetCurrentUser do
  @moduledoc """
  Checks for current user in the session. Refreshes the user and then puts the current user in `conn.assigns["current_user"]` and in the Absinthe context
  """
  @behaviour Plug
  import Plug.Conn

  alias Meadow.Accounts.User

  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> check_config_user()
    |> load_session_user()
    |> add_absinthe_context()
  end

  defp add_absinthe_context(%Plug.Conn{assigns: %{current_user: user}} = conn) do
    token = conn |> Map.get(:req_cookies, %{}) |> Map.get("_meadow_key", "")

    Absinthe.Plug.put_options(conn, context: %{auth_token: token, current_user: user})
  end

  if Mix.env() in [:dev, :test] do
    defp check_config_user(conn) do
      case Application.get_env(:meadow, :force_current_user) do
        nil -> conn
        user_id -> Plug.Conn.assign(conn, :current_user, User.find(user_id))
      end
    end
  else
    defp check_config_user(conn), do: conn
  end

  defp load_session_user(%Plug.Conn{assigns: %{current_user: _user}} = conn), do: conn

  defp load_session_user(conn) do
    user =
      conn
      |> fetch_session
      |> get_session(:current_user)
      |> normalize_role()

    Plug.Conn.assign(conn, :current_user, user)
  end

  defp normalize_role(%User{role: role} = user) when is_binary(role) do
    role =
      role
      |> String.downcase()
      |> String.to_existing_atom()

    %User{user | role: role}
  end

  defp normalize_role(user), do: user
end
