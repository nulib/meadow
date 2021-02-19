defmodule MeadowWeb.Plugs.RequireHttpsProxy do
  @moduledoc """
  Plug to redirect to https on proxied http connections
  """
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _default) do
    if from_insecure_proxy?(conn), do: redirect_to_https(conn), else: conn
  end

  defp from_insecure_proxy?(conn) do
    get_req_header(conn, "x-forwarded-proto") |> Enum.member?("http")
  end

  defp redirect_to_https(conn) do
    with uri <- conn |> request_url() |> URI.parse(),
         new_uri <- uri |> Map.put(:scheme, "https") |> Map.put(:port, nil) do
      conn
      |> Phoenix.Controller.redirect(external: new_uri |> URI.to_string())
      |> halt()
    end
  end
end
