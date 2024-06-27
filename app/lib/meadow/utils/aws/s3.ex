defmodule Meadow.Utils.AWS.S3 do
  @moduledoc """
  S3 utility functions
  """

  alias Meadow.Config

  require Logger

  @doc """
  Lists the file sets in the ingest bucket with the given user prefix.

  ## Parameters

  - user_prefix: The prefix to filter the file sets.

  ## Returns

  A list of file sets in the ingest bucket.
  """
  def list_ingest_bucket_objects(opts \\ []) do
    user_prefix = Keyword.get(opts, :prefix, "")
    bucket = Config.ingest_bucket()

    bucket
    |> ExAws.S3.list_objects(prefix: user_prefix)
    |> ExAws.stream!()
    |> Enum.into([])
    |> Enum.filter(&(!String.ends_with?(&1.key, "/")))
    |> Enum.map(&get_object_metadata(bucket, &1))
  end

  defp get_object_metadata(bucket, file_set) do
    s3_key = "s3://" <> bucket <> "/" <> file_set.key
    mime_type = fetch_mime_type(bucket, file_set.key)

    Map.put(file_set, :mime_type, mime_type)
    |> Map.put(:key, s3_key)
  end

  defp fetch_mime_type(bucket, key) do
    bucket
    |> do_fetch_mime_type(key)
    |> case do
      nil -> "application/octet-stream"
      mime_type -> mime_type
    end
  end

  defp do_fetch_mime_type(bucket, key) do
    case ExAws.S3.head_object(bucket, key) |> ExAws.request() do
      {:ok, %{headers: headers}} -> extract_content_type(headers)
      _ -> nil
    end
  end

  defp extract_content_type(headers) do
    Enum.find_value(headers, fn
      {"content-type", value} -> value
      {"Content-Type", value} -> value
      _ -> false
    end)
  end
end
