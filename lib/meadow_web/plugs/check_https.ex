defmodule MeadowWeb.Plugs.CheckHttps do
  @moduledoc """
  redirects to https if configured to do so
  """
  import Plug.Conn
  alias Meadow.Config

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{scheme: :https} = conn, _), do: conn

  def call(conn, _default) do
    case Config.https() do
      true -> conn |> redirect_to_https()
      {true, port} -> conn |> redirect_to_https(port)
      _ -> conn
    end
  end

  def redirect_to_https(conn, port \\ 443) do
    uri =
      %URI{
        scheme: "https",
        host: conn.host,
        port: port,
        path: conn.request_path,
        query: if(conn.query_string == "", do: nil, else: conn.query_string)
      }
      |> URI.to_string()

    conn
    |> put_resp_header("Location", uri)
    |> send_resp(302, "Redirecting to HTTPS")
    |> halt()
  end
end
