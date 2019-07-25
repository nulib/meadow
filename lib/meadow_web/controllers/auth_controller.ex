defmodule MeadowWeb.AuthController do
  use MeadowWeb, :controller

  def login(conn, _params) do
    conn
    |> Ueberauth.Strategy.OpenAM.handle_request!()
  end

  def callback(conn, _params) do
    conn = Ueberauth.Strategy.OpenAM.handle_callback!(conn)

    body = Ueberauth.Strategy.OpenAM.uid(conn)

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(200, Poison.encode!(body, pretty: true))
  end
end
