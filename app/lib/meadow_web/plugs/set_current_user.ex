defmodule MeadowWeb.Plugs.SetCurrentUser do
  @moduledoc """
  Checks for current user in the session. Refreshes the user and then puts the current user in `conn.assigns["current_user"]` and in the Absinthe context
  """
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    user =
      conn
      |> fetch_session
      |> get_session(:current_user)

    token = conn |> Map.get(:req_cookies, %{}) |> Map.get("_meadow_key", "")

    conn
    |> Absinthe.Plug.put_options(context: %{auth_token: token, current_user: user})
    |> Plug.Conn.assign(:current_user, user)
  end
end
