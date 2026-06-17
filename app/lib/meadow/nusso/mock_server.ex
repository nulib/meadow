defmodule Meadow.NUSSO.MockServer do
  @moduledoc """
  Local mock of the NUSSO agentless-websso API for docker-only development.

  Implements the endpoints `Ueberauth.Strategy.NuSSO` calls — the login
  redirect URL, token validation, and directory search — backed by the same
  user fixtures `Meadow.Directory.MockServer` uses. The login "page" lists
  the fixture users; picking one sets the `nusso` cookie and redirects back
  to the app, so the full login flow works without Apigee.

  The dev secrets tree points `infrastructure/nusso.base_url` at this
  server (port 3948), which also makes `Meadow.Directory` resolve here.
  """

  @cache Meadow.Directory.MockServer.Cache

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/agentless-websso/get-ldap-duo-redirect-url" do
    goto = conn |> get_req_header("goto") |> List.first("/")

    redirect_url =
      "http://#{conn.host}:#{conn.port}/agentless-websso/mock-login?goto=#{URI.encode_www_form(goto)}"

    send_json(conn, 200, %{redirecturl: redirect_url})
  end

  get "/agentless-websso/mock-login" do
    conn = fetch_query_params(conn)
    goto = conn.query_params |> Map.get("goto", "/") |> downgrade_https()

    case Map.get(conn.query_params, "netid") do
      nil ->
        send_login_page(conn, goto)

      netid ->
        conn
        |> put_resp_cookie("nusso", netid)
        |> put_resp_header("location", goto)
        |> send_resp(302, "")
    end
  end

  get "/agentless-websso/validateWebSSOToken" do
    case conn |> get_req_header("webssotoken") |> List.first() do
      empty when empty in [nil, ""] ->
        send_json(conn, 407, %{error: "Missing, invalid, or expired SSO Token"})

      token ->
        send_json(conn, 200, %{netid: token})
    end
  end

  get "/directory-search/res/:field/bas/:value" do
    case Cachex.get!(@cache, "#{field}_#{value}") do
      nil ->
        send_json(conn, 404, %{
          errorCode: 404,
          errorMessage: "No LDAP Data Found for = (#{field}=#{value})"
        })

      data ->
        send_json(conn, 200, %{results: [data]})
    end
  end

  defp send_login_page(conn, goto) do
    links =
      Cachex.stream!(@cache)
      |> Enum.flat_map(fn
        {:entry, "netid_" <> netid, _, _, user} -> [{netid, Map.get(user, "displayName", netid)}]
        _ -> []
      end)
      |> Enum.sort()
      |> Enum.map_join("\n", fn {netid, name} ->
        ~s[<li><a href="?goto=#{URI.encode_www_form(goto)}&netid=#{netid}">#{name} (#{netid})</a></li>]
      end)

    body = """
    <html>
      <head><title>Mock NUSSO Login</title></head>
      <body>
        <h1>Mock NUSSO Login</h1>
        <p>Pick a fixture user to sign in as:</p>
        <ul>#{links}</ul>
      </body>
    </html>
    """

    conn
    |> put_resp_header("content-type", "text/html")
    |> send_resp(200, body)
  end

  # The NuSSO strategy forces the callback URL to https, but local dev
  # serves plain http — undo that on the way back to the app.
  defp downgrade_https("https://" <> rest), do: "http://" <> rest
  defp downgrade_https(url), do: url

  defp send_json(conn, status, payload) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, Jason.encode!(payload))
  end
end
