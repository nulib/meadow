defmodule Meadow.AwsError, do: defexception([:message])

defmodule Meadow.Utils.AWS do
  @moduledoc """
  Utility functions for AWS requests and object management
  """
  alias Meadow.AWS.S3
  alias Meadow.Config
  alias Meadow.Config.Secrets
  alias Meadow.Utils.AWS.MultipartCopy
  alias Meadow.Utils.Pairtree

  use Retry

  require Logger

  @cloudfront_api_version "2020-05-31"

  @doc "Log a message to the configured CloudWatch Logs metrics log"
  def log_metrics(message) do
    with log_config <- Config.ai(:metrics_log) do
      CloudwatchLogs.create_log_stream(log_config[:group], log_config[:stream])

      CloudwatchLogs.put_log_events(log_config[:group], log_config[:stream], [
        %{
          "timestamp" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
          "message" => Jason.encode!(message)
        }
      ])
    end
  end

  def presigned_url(bucket, %{upload_type: "preservation_check", filename: filename}) do
    generate_presigned_url(bucket, "#{filename}", :get)
  end

  def presigned_url(bucket, %{upload_type: "file_set", filename: filename}) do
    generate_presigned_url(bucket, "file_sets/#{Ecto.UUID.generate()}#{Path.extname(filename)}")
  end

  def presigned_url(bucket, %{upload_type: "ingest_sheet"}) do
    generate_presigned_url(bucket, "ingest_sheets/#{Ecto.UUID.generate()}.csv")
  end

  def presigned_url(bucket, %{upload_type: "csv_metadata"}) do
    generate_presigned_url(bucket, "csv_metadata/#{Ecto.UUID.generate()}.csv")
  end

  def create_s3_folder(bucket, name) do
    bucket
    |> check_bucket()
    |> S3.put_object("#{name}/.folder", "")
  end

  def check_object_tags!(bucket, key, required_tags) do
    case S3.has_tags?(bucket, key, required_tags) do
      result when is_boolean(result) -> result
      other -> raise "Unexpected response: #{inspect(other)}"
    end
  end

  def copy_object(dest_bucket, dest_object, src_bucket, src_object, opts \\ []),
    do: MultipartCopy.copy_object(dest_bucket, dest_object, src_bucket, src_object, opts)

  def invalidate_cache(file_set, invalidation_type),
    do: invalidate_cache(file_set, invalidation_type, Config.environment())

  def invalidate_cache(file_set, :pyramid, :dev),
    do: perform_iiif_invalidation("/iiif/3/#{prefix()}/#{file_set.id}/*")

  def invalidate_cache(file_set, :pyramid, :test),
    do: perform_iiif_invalidation("/iiif/3/#{prefix()}/#{file_set.id}/*")

  def invalidate_cache(file_set, :pyramid, _),
    do: perform_iiif_invalidation("/iiif/3/#{file_set.id}/*")

  def invalidate_cache(file_set, :poster, :dev),
    do: perform_iiif_invalidation("/iiif/3/#{prefix()}/posters/#{file_set.id}/*")

  def invalidate_cache(file_set, :poster, :test),
    do: perform_iiif_invalidation("/iiif/3/#{prefix()}/posters/#{file_set.id}/*")

  def invalidate_cache(file_set, :poster, _),
    do: perform_iiif_invalidation("/iiif/3/posters/#{file_set.id}/*")

  def invalidate_cache(_file_set, :streaming, :dev), do: :ok
  def invalidate_cache(_file_set, :streaming, :test), do: :ok

  def invalidate_cache(file_set, :streaming, _),
    do: perform_streaming_invalidation("/#{Pairtree.generate!(file_set.id)}/*")

  @doc """
  Build the credentials Req's `:aws_sigv4` step needs to sign a request for `service`.

  Used for services we talk to outside aws-elixir: OpenSearch (`:es`) and the Bedrock
  event stream.
  """
  def aws_sigv4_options(service) do
    Meadow.AWS.client(service)
    |> aws_sigv4_options(service)
  end

  def aws_sigv4_options(%{access_key_id: access_key_id} = client, service)
      when is_binary(access_key_id) do
    [
      access_key_id: access_key_id,
      secret_access_key: client.secret_access_key,
      region: client.region,
      service: service,
      token: Map.get(client, :session_token)
    ]
  end

  def aws_sigv4_options(_, _) do
    Logger.warning("AWS credentials not present. Proceeding with unsigned request.")
    nil
  end

  defp perform_iiif_invalidation(path),
    do: perform_invalidation(path, Config.iiif_cloudfront_distribution_id())

  defp perform_streaming_invalidation(path),
    do: perform_invalidation(path, Config.streaming_cloudfront_distribution_id())

  defp perform_invalidation(path, nil) do
    Logger.info("Skipping cache invalidation for: #{path}. No distribution id found.")
    :ok
  end

  defp perform_invalidation(path, distribution_id) do
    input = %{
      {"InvalidationBatch",
       %{xmlns: "http://cloudfront.amazonaws.com/doc/#{@cloudfront_api_version}/"}} => %{
        "CallerReference" => "meadow-app-#{Ecto.UUID.generate()}",
        "Paths" => %{"Quantity" => 1, "Items" => %{"Path" => path}}
      }
    }

    Meadow.AWS.client(:cloudfront)
    |> AWS.CloudFront.create_invalidation(distribution_id, input)
    |> case do
      {:ok, _body, _response} ->
        :ok

      other ->
        Logger.error("Unable to clear cache for #{path}: #{inspect(other)}")
        :ok
    end
  end

  defp check_bucket(bucket) do
    case bucket |> ensure_bucket_exists() do
      {:ok, _} -> bucket
      {:error, message} -> raise message
      other -> raise other
    end
  end

  defp ensure_bucket_exists(:undefined), do: {:error, "Bucket: undefined not configured"}

  defp ensure_bucket_exists(bucket) do
    if S3.bucket_exists?(bucket) do
      {:ok, :exists}
    else
      S3.create_bucket!(bucket, "us-east-1")
      {:ok, :created}
    end
  end

  defp generate_presigned_url(bucket, path, method \\ :put) do
    bucket
    |> check_bucket()
    |> then(&S3.presigned_url(method, &1, path))
  end

  defp prefix, do: Secrets.prefix()
end
