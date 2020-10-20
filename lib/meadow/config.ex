defmodule Meadow.Config do
  @moduledoc """
  Convenience methods for retrieving Meadow configuration
  """

  @doc "Retrieve the environment specific URL for the Digital Collections website"
  def digital_collections_url do
    Application.get_env(:meadow, :digital_collections_url)
    |> ensure_trailing_slash()
  end

  @doc "Retrieve the configured indexing interval"
  def index_interval do
    Application.get_env(:meadow, :index_interval, 120_000)
  end

  @doc "Retrieve the configured ingest bucket"
  def ingest_bucket do
    Application.get_env(:meadow, :ingest_bucket)
  end

  @doc "Retrieve the configured preservation bucket"
  def preservation_bucket do
    Application.get_env(:meadow, :preservation_bucket)
  end

  @doc "Retrieve the configured upload bucket"
  def upload_bucket do
    Application.get_env(:meadow, :upload_bucket)
  end

  @doc "Retrieve the configured pyramid bucket"
  def pyramid_bucket do
    Application.get_env(:meadow, :pyramid_bucket)
  end

  @doc "Retrieve the configured pyramid processor"
  def pyramid_processor do
    Application.get_env(
      :meadow,
      :pyramid_processor,
      priv_path("tiff/cli.js")
    )
  end

  @doc "Retrieve the IIIF server endpoint"
  def iiif_server_url do
    Application.get_env(:meadow, :iiif_server_url)
    |> ensure_trailing_slash()
  end

  @doc "Retrieve the IIIF server endpoint"
  def iiif_manifest_url do
    Application.get_env(:meadow, :iiif_manifest_url)
    |> ensure_trailing_slash()
  end

  @doc "Retrieve a list of configured buckets"
  def buckets do
    [
      ingest_bucket(),
      preservation_bucket(),
      upload_bucket(),
      pyramid_bucket()
    ]
  end

  @doc "Retrieve the runtime environment"
  def environment do
    Application.get_env(:meadow, :environment, :dev)
  end

  @doc "Check the runtime environment against a value"
  def environment?(env) do
    environment() == env
  end

  @doc "Return the host:port to redirect to, or nil to use the current host on port 443"
  def ssl_host do
    Application.get_env(:meadow, :ssl_host, nil)
  end

  @doc "Locate a path relative to the priv directory"
  def priv_path(path) do
    :code.priv_dir(:meadow) |> to_string() |> Path.join(path)
  end

  @default_ark_config %{url: "https://ezid.cdlib.org/"}
  @doc "Get ARK/EZID configuration"
  def ark_config do
    with config <- Application.get_env(:meadow, :ark, %{}) do
      Map.merge(@default_ark_config, config)
    end
  end

  @doc "Gather AWS S3 configuration as environment for spawned process"
  def s3_environment do
    with config <- Application.get_env(:ex_aws, :s3) do
      result =
        case config[:access_key_id] do
          nil -> []
          val -> [{'AWS_ACCESS_KEY_ID', to_charlist(val)}]
        end

      result =
        case config[:secret_access_key] do
          nil -> result
          val -> [{'AWS_SECRET_ACCESS_KEY', to_charlist(val)} | result]
        end

      result =
        case config[:region] do
          nil -> result
          val -> [{'AWS_REGION', to_charlist(val)} | result]
        end

      case config[:host] do
        nil ->
          result

        val ->
          endpoint =
            Keyword.get(config, :scheme, "https://")
            |> URI.parse()
            |> Map.put(:host, val)
            |> Map.put(:port, config[:port])
            |> URI.to_string()

          [{'AWS_S3_ENDPOINT', to_charlist(endpoint)} | result]
      end
    end
  end

  @doc "Time to Live for Shared Links"
  def shared_link_ttl do
    Application.get_env(:meadow, :shared_link_ttl, :timer.hours(24 * 7 * 2))
  end

  @doc "Time to wait (in ms) before starting the ingest pipeline"
  def pipeline_delay do
    case Application.get_env(:meadow, :pipeline_delay, 0) do
      n when is_binary(n) -> String.to_integer(n)
      n -> n
    end
  end

  @doc "Ingest progress update interval"
  def progress_ping_interval, do: :timer.seconds(15)

  @doc "Validation subscription update interval"
  def validation_ping_interval, do: :timer.seconds(15)

  defp ensure_trailing_slash(value) do
    if value |> String.ends_with?("/"),
      do: value,
      else: value <> "/"
  end
end
