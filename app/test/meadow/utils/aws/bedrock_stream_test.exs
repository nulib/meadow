defmodule Meadow.Utils.AWS.BedrockStreamTest do
  @moduledoc """
  Exercises BedrockStream's Req/Finch-based streaming against a local Cowboy
  server standing in for Bedrock's chunked event-stream API.
  """
  use ExUnit.Case, async: false

  alias Meadow.Utils.AWS.BedrockStream

  defmodule MockRouter do
    use Plug.Router

    plug(:match)
    plug(:dispatch)

    post "/ok" do
      chunks = :persistent_term.get(:mock_chunks, [])
      delay = :persistent_term.get(:mock_delay, 0)

      conn =
        conn
        |> put_resp_header("content-type", "application/vnd.amazon.eventstream")
        |> send_chunked(200)

      Enum.reduce(chunks, conn, fn chunk, conn ->
        if delay > 0, do: Process.sleep(delay)
        {:ok, conn} = chunk(conn, chunk)
        conn
      end)
    end

    post "/bad_status" do
      conn
      |> put_resp_header("content-type", "application/vnd.amazon.eventstream")
      |> send_resp(403, "forbidden")
    end

    post "/bad_content_type" do
      conn
      |> put_resp_header("content-type", "application/json")
      |> send_chunked(200)
    end

    post "/hang" do
      conn
      |> put_resp_header("content-type", "application/vnd.amazon.eventstream")
      |> send_chunked(200)

      Process.sleep(:infinity)
    end
  end

  setup_all do
    port = free_port()
    {:ok, _} = Plug.Cowboy.http(MockRouter, [], port: port)
    on_exit(fn -> Plug.Cowboy.shutdown(MockRouter.HTTP) end)
    {:ok, port: port}
  end

  defp free_port do
    {:ok, socket} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(socket)
    :gen_tcp.close(socket)
    port
  end

  defp event_chunk(payload) do
    body = Jason.encode!(payload)
    headers_length = 0
    body_length = byte_size(body)
    message_overhead = 12 + 4
    message_total_length = message_overhead + headers_length + body_length

    prelude = <<message_total_length::unsigned-32, headers_length::unsigned-32>>
    prelude_checksum = :erlang.crc32(prelude)

    message = prelude <> <<prelude_checksum::unsigned-32>> <> body
    message_checksum = :erlang.crc32(message)

    message <> <<message_checksum::unsigned-32>>
  end

  # A client pointed at the local mock rather than Bedrock. Credentials are present so
  # the request still goes through Req's sigv4 step, exactly as it does in production.
  defp client(port) do
    %AWS.Client{
      access_key_id: "fake",
      secret_access_key: "fake",
      region: "us-east-1",
      endpoint: "localhost",
      proto: "http",
      port: port
    }
  end

  defp url(port, path), do: "http://localhost:#{port}#{path}"

  defp data, do: %{"prompt" => "hi"}

  test "streams and decodes multiple chunks", %{port: port} do
    :persistent_term.put(:mock_chunks, [
      event_chunk(%{"delta" => %{"text" => "hello "}}),
      event_chunk(%{"delta" => %{"text" => "world"}})
    ])

    :persistent_term.put(:mock_delay, 50)

    result =
      BedrockStream.stream_objects!(client(port), url(port, "/ok"), data())
      |> Enum.to_list()

    assert result == [
             chunk: %{"delta" => %{"text" => "hello "}},
             chunk: %{"delta" => %{"text" => "world"}}
           ]
  end

  test "raises on non-200 status", %{port: port} do
    assert_raise Meadow.AWS.Error, ~r/rejected: 403/, fn ->
      BedrockStream.stream_objects!(client(port), url(port, "/bad_status"), data())
      |> Enum.to_list()
    end
  end

  test "raises on unexpected content-type", %{port: port} do
    assert_raise Meadow.AWS.Error, ~r/Expected content-type/, fn ->
      BedrockStream.stream_objects!(client(port), url(port, "/bad_content_type"), data())
      |> Enum.to_list()
    end
  end

  test "raises when the stream stalls past the timeout", %{port: port} do
    original = Application.get_env(:meadow, :ai, [])
    Application.put_env(:meadow, :ai, Keyword.put(original, :transcriber_stream_timeout, 200))
    on_exit(fn -> Application.put_env(:meadow, :ai, original) end)

    assert_raise Meadow.AWS.Error, ~r/timed out/, fn ->
      BedrockStream.stream_objects!(client(port), url(port, "/hang"), data())
      |> Enum.to_list()
    end
  end
end
