defmodule MeadowWeb.AuthController do
  use MeadowWeb, :controller

  plug Ueberauth
  alias Meadow.Accounts
  alias Ueberauth.Auth

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    referer =
      conn
      |> extract_referer()

    conn
    |> redirect(external: referer)
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Auth{extra: %{raw_info: %{user: user_info}}}}} = conn,
        _params
      ) do
    referer =
      conn
      |> extract_referer()

    case Accounts.authorize_user_login(user_info) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, user)
        |> configure_session(renew: true)
        |> redirect(external: referer)

      {:error, _message} ->
        conn
        |> redirect(external: referer)
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> Plug.Conn.assign(:current_user, nil)
    |> redirect(to: "/")
  end

  defp extract_referer(%Plug.Conn{} = conn) do
    conn
    |> Plug.Conn.get_req_header("referer")
    |> extract_referer()
  end

  defp extract_referer([referer | _]), do: referer
  defp extract_referer([]), do: "/"
end
