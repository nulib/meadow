defmodule MeadowWeb.AuthController do
  use MeadowWeb, :controller
  alias Ueberauth.Strategy.OpenAM

  def login(conn, _params) do
    conn
    |> OpenAM.handle_request!()
  end

  def callback(conn, _params) do
    conn = OpenAM.handle_callback!(conn)

    body = OpenAM.uid(conn)

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, Poison.encode!(body, pretty: true))
  end
end
