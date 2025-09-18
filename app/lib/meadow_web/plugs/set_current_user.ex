defmodule MeadowWeb.Plugs.SetCurrentUser do
  @moduledoc """
  Checks for current user in the session. Refreshes the user and then puts the current user in `conn.assigns["current_user"]` and in the Absinthe context
  """
  @behaviour Plug
  import Plug.Conn

  alias Meadow.Accounts.User

  def init(opts), do: opts

  def call(conn, _) do
    user =
      conn
      |> fetch_session
      |> get_session(:current_user)
      |> normalize_role()
      |> IO.inspect()

    token = conn |> Map.get(:req_cookies, %{}) |> Map.get("_meadow_key", "")

    conn
    |> Absinthe.Plug.put_options(context: %{auth_token: token, current_user: user})
    |> Plug.Conn.assign(:current_user, user)
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
