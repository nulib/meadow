defmodule Meadow.Utils.Sitemap.S3Store do
  @moduledoc """
  `Sitemapper.Store` implementation backed by `Meadow.AWS.S3`.

  Sitemapper ships its own `Sitemapper.S3Store`, but only compiles it when `ex_aws_s3`
  is present. Meadow no longer depends on ExAws, so this is the equivalent written
  against Meadow's own S3 client.

  ## Configuration

  - `:bucket` (required) -- the bucket to write to
  - `:path` -- a prefix prepended to the filename
  - `:extra_props` -- additional options passed through to `Meadow.AWS.S3.put_object/4`
  """
  @behaviour Sitemapper.Store

  alias Meadow.AWS.S3

  @impl Sitemapper.Store
  def write(filename, body, config) do
    bucket = Keyword.fetch!(config, :bucket)

    opts =
      [
        content_type: content_type(filename),
        cache_control: "must-revalidate",
        acl: "public-read"
      ] ++ Keyword.get(config, :extra_props, [])

    S3.put_object!(bucket, key(filename, config), body, opts)

    :ok
  end

  defp content_type(filename) do
    if String.ends_with?(filename, ".gz") do
      "application/x-gzip"
    else
      "application/xml"
    end
  end

  defp key(filename, config) do
    case Keyword.fetch(config, :path) do
      :error -> filename
      {:ok, path} -> Path.join([path, filename])
    end
  end
end
