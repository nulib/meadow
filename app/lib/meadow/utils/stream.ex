defmodule Meadow.Utils.Stream do
  @moduledoc """
  Functions to provide chunk streams from http:// and s3:// URLs
  """

  require Logger

  alias ExAws.S3

  def exists?("s3://" <> _ = url) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(url) do
      case S3.head_object(bucket, key) |> ExAws.request() do
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

  def copy("s3://" <> _ = source, "s3://" <> _ = dest) do
    with {source_bucket, source_key} <- parse_s3_uri(source),
         {dest_bucket, dest_key} <- parse_s3_uri(dest) do
      S3.put_object_copy(dest_bucket, dest_key, source_bucket, source_key,
        metadata_directive: :COPY
      )
      |> ExAws.request!()
    end
  end

  def copy("file://" <> source, "file://" <> dest) do
    File.cp(source, dest)
  end

  def copy("s3://" <> _ = source, "file://" <> dest) do
    stream_from(source) |> Stream.into(File.stream!(dest)) |> Stream.run()
  end

  def copy("file://" <> source, "s3://" <> _ = dest) do
    %{size: size} = File.stat!(source)

    {dest_bucket, dest_key} = parse_s3_uri(dest)

    if size > 5 * 1024 * 1024 do
      S3.Upload.stream_file(source) |> S3.upload(dest_bucket, dest_key)
    else
      content = File.read!(source)
      S3.put_object(dest_bucket, dest_key, content)
    end
    |> ExAws.request!()
  end

  def list_contents("s3://" <> _ = url) do
    {bucket, prefix} = parse_s3_uri(url)

    S3.list_objects_v2(bucket, prefix: prefix)
    |> ExAws.stream!()
    |> Stream.map(fn %{key: key} -> "s3://#{bucket}/#{key}" end)
    |> Enum.to_list()
  end

  def list_contents("file://" <> path) do
    Path.wildcard("#{path}/**/*")
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(fn file -> "file://#{file}" end)
  end

  def stream_from("s3://" <> _ = url) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(url) do
      S3.download_file(bucket, key, :memory) |> ExAws.stream!()
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

  defp parse_s3_uri(url) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(url) do
      {bucket, key}
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
          Logger.warning(msg)
          raise Meadow.TimeoutError, message: msg
        end
    end
  end

  defp async_stream_after(%HTTPoison.AsyncResponse{id: id}), do: :hackney.stop_async(id)

  def by_line(enum) do
    enum
    |> Stream.concat([:halt])
    |> Elixir.Stream.transform(
      "",
      &line_stream_reduce/2
    )
  end

  defp line_stream_reduce(:halt, buffer), do: {[buffer], ""}

  defp line_stream_reduce(chunk, buffer) do
    case (buffer <> chunk) |> String.split(~r/(?<=\n)/) |> Enum.reverse() do
      [remainder | []] -> {[remainder], ""}
      [remainder | lines] -> {Enum.reverse(lines), remainder}
    end
  end
end
