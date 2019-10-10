defmodule Meadow.Utils.Stream do
  @moduledoc """
  Functions to provide chunk streams from http:// and s3:// URLs
  """
  def stream_from("s3://" <> _ = url), do: url |> presigned_url_for() |> stream_from()

  def stream_from(url) do
    Elixir.Stream.resource(
      fn ->
        HTTPoison.get!(
          url,
          %{},
          stream_to: self(),
          async: :once
        )
      end,
      fn %HTTPoison.AsyncResponse{id: id} = resp ->
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
        end
      end,
      fn %HTTPoison.AsyncResponse{id: id} ->
        :hackney.stop_async(id)
      end
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
end
