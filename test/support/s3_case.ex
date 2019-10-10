defmodule Meadow.S3Case do
  @moduledoc """
  This module includes the setup and mocks for testing loading and streaming
  fixtures from S3
  """
  use ExUnit.CaseTemplate

  setup tags do
    Application.ensure_all_started(:bypass)

    content =
      case tags[:content] do
        x when is_binary(x) -> :binary.bin_to_list(x)
        x when is_bitstring(x) -> x
        x -> :binary.bin_to_list(to_string(x))
      end

    chunk_size = tags[:chunk_size] || 4

    url_path = "/#{tags[:bucket]}/#{tags[:key]}"
    bypass = Bypass.open(port: ExAws.Config.new(:s3).port)

    Bypass.stub(bypass, "GET", url_path, fn conn ->
      conn =
        conn
        |> Plug.Conn.send_chunked(200)

      content
      |> Enum.chunk_every(chunk_size)
      |> Enum.each(fn chunk -> conn |> Plug.Conn.chunk(chunk) end)

      conn
    end)

    {:ok, port: bypass.port}
  end
end
