defmodule Meadow.Utils.Stream do
  @moduledoc """
  Functions to provide chunk streams from http:// and s3:// URLs
  """

  defmodule Timeout do
    defexception [:message]
  end

  require Logger

  def exists?("s3://" <> _ = url) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(url) do
      case ExAws.S3.head_object(bucket, key) |> ExAws.request() do
        {:ok, %{status_code: status}} when status in 200..299 -> true
        _ -> false
      end
    end
  end

  def exists?("file://" <> filename), do: File.exists?(filename)

  def exists?(url) do
    case HTTPoison.head(url, %{}, follow_redirect: true) do
      {:ok, %{status_code: status}} when status in 200..299 -> true
      _ -> false
    end
  end

  def stream_from("s3://" <> _ = url) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(url) do
      ExAws.S3.download_file(bucket, key, :memory) |> ExAws.stream!()
    end
  end

  def stream_from("file://" <> filename), do: File.stream!(filename)

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
