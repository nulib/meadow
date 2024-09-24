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
    opts =
      opts
      |> Keyword.put_new(:delimiter, "/")
      |> Keyword.put_new(:prefix, "")
      |> Keyword.put_new(:max_keys, 500)

    bucket = Config.ingest_bucket()

    %{body: %{contents: contents, common_prefixes: common_prefixes}} =
      bucket
      |> ExAws.S3.list_objects_v2(opts)
      |> ExAws.request!()

    %{
      objects:
        contents
        |> Enum.filter(&(!String.ends_with?(&1.key, "/")))
        |> Enum.map(&get_object_metadata(bucket, &1)),
      folders: Enum.map(common_prefixes, fn %{prefix: folder} -> String.trim(folder, "/") end)
    }
  end

  defp get_object_metadata(bucket, file_set) do
    s3_key = "s3://" <> Path.join(bucket, file_set.key)
    mime_type = fetch_mime_type(bucket, file_set.key)

    Map.put(file_set, :mime_type, mime_type)
    |> Map.put(:uri, s3_key)
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
