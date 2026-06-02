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
    case cli(~w(funnel status --json)) do
      {:ok, json} ->
        case JSON.decode(json) do
          {:ok, json} -> find_proxy(json, [http_port(), https_port()])
          {:error, _} = err -> err
        end

      {:error, _} = err ->
        err
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

  defp cli(args) do
    {mod, fun} = Application.get_env(:meadow, :system_cmd, {System, :cmd})

    case apply(mod, fun, ["tailscale", args, [stderr_to_stdout: true]]) do
      {output, 0} -> {:ok, String.trim(output)}
      {output, code} -> {:error, {code, String.trim(output)}}
    end
  rescue
    e in ErlangError ->
      case e do
        %ErlangError{original: original, reason: reason} ->
          {:error, {original, reason}}

        other ->
          reraise(other, __STACKTRACE__)
      end

    e ->
      reraise(e, __STACKTRACE__)
  end
end
