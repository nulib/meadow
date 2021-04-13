defmodule Meadow.Utils.ArkClient.MockServer do
  @moduledoc """
  Mock EZID API server for testing Meadow.Ark

  Mints and stores ARKs using a naive format of:

      shoulder + number of milliseconds since 2020-06-01T00:00:00 padded to 8 digits]

  Backed by an ETS store, so ARK metadata is cleared every time the server is stopped.

  Also has the ability to send inter-process messages in order to make testing
  easier.
  """

  use Plug.Router
  plug :match
  plug :dispatch

  @cache Meadow.Utils.ArkClient.MockServer.Cache

  @doc """
  Specify a process to send messages to about requests. Good for testing
  request serialization.
  """
  def send_to(nil) do
    Cachex.del!(@cache, :send_to)
    :ok
  end

  def send_to(target) when is_pid(target) do
    Cachex.put!(@cache, :send_to, target)
    :ok
  end

  def send_to(target) do
    {:error, "#{target} is not a valid message recipient"}
  end

  get "/id/*stem" do
    ark = Enum.join(stem, "/")

    send_message({:get, :ark, ark})
    send_message({:get, :credentials, Plug.BasicAuth.parse_basic_auth(conn)})

    case Cachex.get!(@cache, ark) do
      nil -> send_resp(conn, 404, "error: bad request - no such identifier")
      data -> send_resp(conn, 200, "success: #{ark}\n#{anvl_encode(data)}")
    end
  end

  post "/shoulder/*stem" do
    try do
      shoulder = Enum.join(stem, "/")

      ark = shoulder <> identifier()

      {:ok, body, _} = Plug.Conn.read_body(conn)

      body = anvl_decode(body)

      send_message({:post, :shoulder, shoulder})
      send_message({:post, :credentials, Plug.BasicAuth.parse_basic_auth(conn)})
      send_message({:post, :body, body})

      Cachex.put!(@cache, ark, body)
      send_resp(conn, 201, "success: #{ark}")
    rescue
      ArgumentError ->
        send_resp(conn, 400, "error: bad request - ANVL parse error (percent-decode error)")
    end
  end

  put "/id/*stem" do
    try do
      ark = Enum.join(stem, "/")
      {:ok, body, _} = Plug.Conn.read_body(conn)

      body = anvl_decode(body)

      send_message({:put, :ark, ark})
      send_message({:put, :credentials, Plug.BasicAuth.parse_basic_auth(conn)})
      send_message({:put, :body, body})

      Cachex.put!(@cache, ark, body)
      send_resp(conn, 200, "success: #{ark}\n#{body}")
    rescue
      ArgumentError ->
        send_resp(conn, 400, "error: bad request - ANVL parse error (percent-decode error)")
    end
  end

  defp anvl_encode(body), do: anvl_process(body, &URI.encode/1)
  defp anvl_decode(body), do: anvl_process(body, &URI.decode/1)

  defp anvl_process(body, func) do
    body
    |> String.split(~r/\r?\n/)
    |> Enum.map(fn line ->
      [key, value] = String.split(line, ~r/:\s*/, parts: 2)
      [key, func.(value)] |> Enum.join(": ")
    end)
    |> Enum.join("\n")
  end

  defp send_message(message) do
    case Cachex.get!(@cache, :send_to) do
      nil -> :noop
      process -> send(process, message)
    end
  end

  defp identifier do
    :rand.uniform(99_999_999)
    |> Integer.to_string()
    |> String.pad_leading(8, "0")
  end
end
