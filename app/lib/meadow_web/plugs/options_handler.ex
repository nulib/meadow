defmodule MeadowWeb.Plugs.OptionsHandler do
  @moduledoc """
  A plug to handle CORS preflight OPTIONS requests on the API pipeline.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{method: "OPTIONS"} = conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first() || "*"
    requested_headers = get_req_header(conn, "access-control-request-headers") |> List.first() || ""

    conn
    |> put_resp_header("allow", "GET, POST, OPTIONS")
    |> put_resp_header("access-control-allow-origin", origin)
    |> put_resp_header("access-control-allow-methods", "GET, POST, OPTIONS")
    |> put_resp_header("access-control-allow-headers", requested_headers)
    |> send_resp(204, "")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
