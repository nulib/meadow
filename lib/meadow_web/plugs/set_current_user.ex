defmodule MeadowWeb.Plugs.SetCurrentUser do
  @moduledoc """
  checks for auth token in the reqeust and puts the current user into the Absinthe Context
  """
  @behaviour Plug
  alias Meadow.Accounts
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    conn
    |> fetch_session
    |> get_session(:current_user)
    |> refresh_user()
  end

  defp refresh_user(%{username: username}) do
    case Accounts.authorize_user_login(username) do
      {:ok, user} -> %{current_user: user}
      _ -> %{}
    end
  end

  defp refresh_user(_), do: %{}
end
