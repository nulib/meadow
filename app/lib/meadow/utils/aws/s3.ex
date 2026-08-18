defmodule Meadow.Utils.AWS.S3 do
  @moduledoc """
  S3 utility functions
  """

  alias Meadow.AWS.S3
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
    listing = S3.list_objects!(bucket, opts)

    %{
      objects:
        listing.objects
        |> Enum.filter(&(!String.ends_with?(&1.key, "/")))
        |> Enum.map(&get_object_metadata(bucket, &1)),
      folders: Enum.map(listing.prefixes, &String.trim(&1, "/"))
    }
  end

  defp get_object_metadata(bucket, file_set) do
    s3_key = "s3://" <> Path.join(bucket, file_set.key)
    mime_type = fetch_mime_type(bucket, file_set.key)

    Map.put(file_set, :mime_type, mime_type)
    |> Map.put(:uri, s3_key)
  end

  defp fetch_mime_type(bucket, key) do
    case S3.head_object(bucket, key) do
      {:ok, %{content_type: content_type}} when is_binary(content_type) -> content_type
      _ -> "application/octet-stream"
    end
  end
end
