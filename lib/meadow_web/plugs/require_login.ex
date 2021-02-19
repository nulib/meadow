defmodule MeadowWeb.Plugs.RequireLogin do
  @moduledoc """
  checks for current user in the conn
  """
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _default) do
    case conn.assigns[:current_user] do
      %Meadow.Accounts.User{} ->
        conn

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(401, "Unauthorized")
        |> send_resp()
        |> halt()
    end
  end
end
