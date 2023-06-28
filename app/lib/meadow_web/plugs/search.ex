defmodule MeadowWeb.Plugs.Search do
  @moduledoc """
  Plug to proxy search requests from the front end
  """
  import Plug.Conn

  @behaviour Plug
  @accepted_methods ["POST", "GET", "OPTIONS", "HEAD"]

  require Logger

  alias Meadow.Search.HTTP

  def init(default), do: default

  def call(conn, opts) do
    case conn.method in @accepted_methods do
      true ->
        process_request(conn, opts)

      false ->
        conn
        |> put_resp_content_type("application/json")
        |> resp(400, "Bad Request")
        |> send_resp()
    end
  end

  def process_request(conn, _default) do
    body = extract_body(conn)
    [_base, path] = String.split(conn.request_path, "/_search", parts: 2)
    query_string = extract_query_string(conn.query_string) |> URI.encode()

    method =
      case conn.method do
        x when is_atom(x) -> x
        x when is_binary(x) -> String.to_atom(x)
        x -> String.to_atom(to_string(x))
      end

    case HTTP.request(method, path <> query_string, body, []) do
      {:ok, response} ->
        conn
        |> assign(:updated_req_body, body)
        |> put_resp_content_type("application/json")
        |> resp(200, Jason.encode!(response.body))
        |> send_resp()

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("#{__MODULE__} error: #{reason}")

        conn
        |> put_resp_content_type("application/json")
        |> resp(500, Jason.encode!(reason))
        |> send_resp()

      other ->
        other
    end
  end

  defp extract_query_string(<<" "::binary, rest::binary>>), do: extract_query_string(rest)

  defp extract_query_string(string) when string == "",
    do: ""

  defp extract_query_string(string) when is_binary(string),
    do: "?#{string}"

  defp extract_body(%Plug.Conn{body_params: %Plug.Conn.Unfetched{aspect: :body_params}} = conn) do
    {:ok, body, _conn} = read_body(conn)
    fix_multiline_json(body, conn)
  end

  defp extract_body(conn) do
    conn.body_params
  end

  defp fix_multiline_json(body, conn) do
    if get_req_header(conn, "content-type") == ["application/x-ndjson"] do
      body
      |> String.trim()
      |> String.split("\n")
      |> Enum.map_join("\n", fn line ->
        line
        |> Jason.decode!()
        |> add_track_total_hits()
        |> Jason.encode!()
      end)
      |> Kernel.<>("\n")
    else
      body
      |> Jason.decode!()
      |> add_track_total_hits()
      |> Jason.encode!()
    end
  end

  defp add_track_total_hits(%{"query" => _, "track_total_hits" => _} = line), do: line

  defp add_track_total_hits(%{"query" => _} = line) do
    line
    |> Map.put("track_total_hits", true)
  end

  defp add_track_total_hits(line), do: line
end
