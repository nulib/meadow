defmodule MeadowWeb.Plugs.SetCurrentUser do
  @moduledoc """
  checks for auth token in the reqeust and puts the current user into the Absinthe Context
  """
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    user =
      conn
      |> fetch_session
      |> get_session(:current_user)

    case user do
      %{username: _username, email: _email, display_name: _display_name} -> %{current_user: user}
      _ -> %{}
    end
  end
end
