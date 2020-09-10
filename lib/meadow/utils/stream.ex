defmodule Meadow.Utils.Stream do
  @moduledoc """
  Functions to provide chunk streams from http:// and s3:// URLs
  """

  defmodule Timeout do
    defexception [:message]
  end

  require Logger

  def stream_from("s3://" <> _ = url), do: url |> presigned_url_for() |> stream_from()

  def stream_from(url) do
    Elixir.Stream.resource(
      fn -> async_stream_start(url) end,
      &async_stream_next/1,
      &async_stream_after/1
    )
  end

  def presigned_url_for(s3_url) do
    %{host: bucket, path: "/" <> key} = URI.parse(s3_url)

    with {:ok, result} <-
           ExAws.Config.new(:s3)
           |> ExAws.S3.presigned_url(:get, bucket, key) do
      result
    end
  end

  defp async_stream_start(url), do: HTTPoison.get!(url, %{}, stream_to: self(), async: :once)

  defp async_stream_next(%HTTPoison.AsyncResponse{id: id} = resp) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id} ->
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        HTTPoison.stream_next(resp)
        {[chunk], resp}

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:halt, resp}

      {:EXIT, _pid, :normal} ->
        {[], resp}

      other ->
        Logger.warn("Unexpected message received from #{inspect(resp)}: #{inspect(other)}")
        {[], resp}
    after
      5_000 ->
        with msg <- "No message received from #{inspect(resp)} in 5 seconds." do
          Logger.warn(msg)
          raise __MODULE__.Timeout, message: msg
        end
    end
  end

  defp async_stream_after(%HTTPoison.AsyncResponse{id: id}), do: :hackney.stop_async(id)
end
