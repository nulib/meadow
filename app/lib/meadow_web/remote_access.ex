defmodule MeadowWeb.RemoteAccess do
  @moduledoc """
  Routes requests to the public funnel URL if a funnel is active, otherwise to the local server URL.
  """

  require Logger

  @doc """
  Returns the funnel URL if a funnel is active, otherwise the local server URL.
  """
  def url(path \\ nil) do
    case detect_funnel() do
      {:ok, funnel_url} ->
        case path do
          nil -> URI.to_string(funnel_url)
          _ -> URI.merge(funnel_url, path) |> URI.to_string()
        end
        |> String.trim_trailing("/")

      {:error, _} ->
        Path.join(default_url(), path || "")
    end
  end

  defp detect_funnel do
    case tailscale("serve-config") do
      {:ok, json} -> find_proxy(json, [http_port(), https_port()])
      {:error, _} = err -> err
    end
  end

  defp default_url do
    cfg = Application.get_env(:meadow, MeadowWeb.Endpoint) |> get_in([:url])
    scheme = Keyword.get(cfg, :scheme, "http")
    host = Keyword.get(cfg, :host, "localhost")
    port = Keyword.get(cfg, :port, http_port())

    case {scheme, port} do
      {"https", 443} -> "https://#{host}"
      {"http", 80} -> "http://#{host}"
      _ -> "#{scheme}://#{host}:#{port}"
    end
  end

  defp find_proxy(map, target_ports) do
    top_level_web = Map.get(map, "Web", %{})

    foreground_web =
      map
      |> Map.get("Foreground", %{})
      |> Map.values()
      |> Enum.flat_map(fn fg -> Map.get(fg, "Web", %{}) |> Map.to_list() end)
      |> Map.new()

    Map.merge(top_level_web, foreground_web)
    |> Enum.find_value(fn {host, %{"Handlers" => handlers}} ->
      find_handler(host, handlers, target_ports)
    end)
    |> case do
      {host, "/"} -> {:ok, URI.parse("https://#{host}/")}
      {host, path} -> {:ok, URI.parse("https://#{host}#{path}/")}
      nil -> {:error, :no_funnel}
    end
  end

  defp find_handler(host, handlers, target_ports) do
    Enum.find_value(handlers, fn {path, handler} ->
      port =
        Map.get(handler, "Proxy")
        |> URI.parse()
        |> Map.get(:port)

      if Enum.member?(target_ports, port), do: {host, path}, else: nil
    end)
  end

  defp http_port do
    Application.get_env(:meadow, MeadowWeb.Endpoint) |> get_in([:http, :port])
  end

  defp https_port do
    Application.get_env(:meadow, MeadowWeb.Endpoint) |> get_in([:https, :port])
  end

  defp tailscale(arg) when is_binary(arg) do
    tailscale(url: arg)
  end

  defp tailscale(args) do
    case tailscale_socket() do
      {:error, _} = err ->
        err

      {:ok, socket} ->
        req_opts =
          [
            base_url: "http://local-tailscaled.sock/localapi/v0/",
            headers: [{"Host", "local-tailscaled.sock"}, {"Accept", "application/json"}],
            unix_socket: socket
          ]
          |> Keyword.merge(args)

        case Req.get(req_opts) do
          {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
          {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp tailscale_socket do
    [
      System.get_env("TS_SOCKET"),
      "/var/run/tailscale/tailscaled.sock",
      "/var/run/tailscaled.sock",
      "/run/tailscale/tailscaled.sock",
      "/run/tailscaled.sock",
      "/var/run/tailscaled.socket",
      "/run/tailscaled.socket"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.find(fn path ->
      case File.stat(path) do
        {:ok, %File.Stat{type: :other, access: :read_write}} -> true
        _ -> false
      end
    end)
    |> case do
      nil -> {:error, :no_tailscale_socket}
      path -> {:ok, path}
    end
  end
end
