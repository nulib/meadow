defmodule MeadowWeb.Plugs.RequireHttps do
  @moduledoc """
  Plug to redirect to https on http connections
  """
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _default) do
    cond do
      is_http?(conn) -> redirect_to_https(conn)
      is_forwarded_http?(conn) -> redirect_to_https(conn)
      true -> conn
    end
  end

  defp is_http?(conn) do
    conn.scheme == :http
  end

  defp is_forwarded_http?(conn) do
    get_req_header(conn, "x-forwarded-proto") |> Enum.member?("http")
  end

  defp redirect_to_https(conn) do
    with uri <- conn |> request_url() |> URI.parse(),
         https_config <- MeadowWeb.Endpoint.config(:https) do
      case https_config do
        false ->
          conn

        config ->
          new_uri = uri |> Map.put(:scheme, "https") |> Map.put(:port, config[:port])

          conn
          |> Phoenix.Controller.redirect(external: new_uri |> URI.to_string())
          |> halt()
      end
    end
  end
end
