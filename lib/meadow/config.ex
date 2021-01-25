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

  @doc "Retrieve configured lambda scripts"
  def lambda_config(config_key) do
    case Application.get_env(:meadow, :lambda, []) |> Keyword.get(config_key) do
      nil -> {:error, :unknown}
      {:lambda, lambda} -> {:lambda, lambda}
      {:local, {script, handler}} -> {:local, {priv_path(script), handler}}
    end
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

  @doc "Gather configuration variables as environment for spawned process"
  def aws_environment do
    with config <- Application.get_env(:ex_aws, :s3),
         working_dir <- Application.get_env(:meadow, :pyramid_tiff_working_dir) do
      []
      |> build_environment(config[:access_key_id], "AWS_ACCESS_KEY_ID")
      |> build_environment(config[:secret_access_key], "AWS_SECRET_ACCESS_KEY")
      |> build_environment(config[:region], "AWS_REGION")
      |> build_environment(extract_endpoint(config), "AWS_S3_ENDPOINT")
      |> build_environment(working_dir, "TMPDIR")
    end
  end

  defp extract_endpoint(config) do
    case config[:host] do
      nil ->
        nil

      val ->
        Keyword.get(config, :scheme, "https://")
        |> URI.parse()
        |> Map.put(:host, val)
        |> Map.put(:port, config[:port])
        |> URI.to_string()
    end
  end

  defp build_environment(accumulator, value, variable_name) do
    case value do
      nil -> accumulator
      val -> [{to_charlist(variable_name), to_charlist(val)} | accumulator]
    end
  end

  @doc "Time to Live for Shared Links"
  def shared_link_ttl do
    Application.get_env(:meadow, :shared_link_ttl, :timer.hours(24 * 7 * 2))
  end

  @doc "Time to wait (in ms) before starting the ingest pipeline"
  def pipeline_delay, do: configured_integer_value(:pipeline_delay)

  @doc "Ingest progress update interval"
  def progress_ping_interval,
    do: configured_integer_value(:progress_ping_interval, :timer.seconds(15))

  @doc "Validation subscription update interval"
  def validation_ping_interval,
    do: configured_integer_value(:validation_ping_interval, :timer.seconds(15))

  def workers do
    System.get_env("MEADOW_PROCESSES", "ALL")
    |> String.split(~r/\s*,\s*/)
    |> Enum.map(&Inflex.underscore/1)
  end

  defp configured_integer_value(key, default \\ 0) do
    case Application.get_env(:meadow, key, default) do
      n when is_binary(n) -> String.to_integer(n)
      n -> n
    end
  end

  defp ensure_trailing_slash(value) do
    if value |> String.ends_with?("/"),
      do: value,
      else: value <> "/"
  end
end
