defmodule Meadow.AwsError, do: defexception([:message])

defmodule Meadow.Utils.AWS do
  @moduledoc """
  Utility functions for AWS requests and object management
  """
  alias Meadow.Config
  alias Meadow.Config.Secrets
  alias Meadow.Utils.AWS.MultipartCopy
  alias Meadow.Utils.Pairtree

  use Retry

  require Logger

  @doc "Log a message to the configured CloudWatch Logs metrics log"
  def log_metrics(message) do
    with log_config <- Config.ai(:metrics_log) do
      CloudwatchLogs.create_log_stream(log_config[:group], log_config[:stream])
      |> ExAws.request()

      CloudwatchLogs.put_log_events(log_config[:group], log_config[:stream], [
        %{
          "timestamp" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
          "message" => Jason.encode!(message)
        }
      ])
      |> ExAws.request()
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
    |> ExAws.S3.put_object("#{name}/.folder", "")
    |> ExAws.request()
  end

  def add_aws_signature(request) do
    request.headers ++ generate_aws_signature(request)
  end

  def check_object_tags!(bucket, key, required_tags) do
    case ExAws.S3.get_object_tagging(bucket, key) |> ExAws.request() do
      {:ok, %{status_code: 200, body: %{tags: actual_tags}}} ->
        existing_tags = Enum.map(actual_tags, &Map.get(&1, :key))
        required_tags -- existing_tags == []

      other ->
        raise "Unexpected response: #{other}"
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

  defp perform_iiif_invalidation(path),
    do: perform_invalidation(path, Config.iiif_cloudfront_distribution_id())

  defp perform_streaming_invalidation(path),
    do: perform_invalidation(path, Config.streaming_cloudfront_distribution_id())

  defp perform_invalidation(path, nil) do
    Logger.info("Skipping cache invalidation for: #{path}. No distribution id found.")
    :ok
  end

  defp perform_invalidation(path, distribution_id) do
    version = "2020-05-31"
    caller_reference = "meadow-app-#{Ecto.UUID.generate()}"

    data = """
    <?xml version="1.0" encoding="UTF-8"?>
    <InvalidationBatch xmlns="http://cloudfront.amazonaws.com/doc/#{version}/">
        <CallerReference>#{caller_reference}</CallerReference>
        <Paths>
          <Items>
              <Path>#{path}</Path>
          </Items>
          <Quantity>1</Quantity>
        </Paths>
    </InvalidationBatch>
    """

    operation = %ExAws.Operation.RestQuery{
      action: :create_invalidation,
      body: data,
      http_method: :post,
      path: "/#{version}/distribution/#{distribution_id}/invalidation",
      service: :cloudfront
    }

    case operation |> ExAws.request() do
      {:ok, %{status_code: status_code}} when status_code in 200..299 ->
        :ok

      _ ->
        Logger.error("Unable to clear cache for #{path}")
        :ok
    end
  end

  defp generate_aws_signature(request) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    %{host: host} = URI.parse(request.url)

    config = ExAws.Config.new(:es)

    headers =
      case Map.get(config, :security_token) do
        nil -> [{"Host", host}]
        security_token -> [{"Host", host}, {"X-Amz-Security-Token", security_token}]
      end

    encode_fn = fn c -> (URI.char_unescaped?(c) || URI.char_reserved?(c)) && c != ?* end

    :aws_signature.sign_v4(
      config.access_key_id,
      config.secret_access_key,
      config.region,
      "es",
      {{now.year, now.month, now.day}, {now.hour, now.minute, now.second}},
      request.method |> to_string() |> String.upcase(),
      request.url |> URI.encode(encode_fn),
      headers,
      request.body,
      []
    )
  end

  defp check_bucket(bucket) do
    case bucket |> ensure_bucket_exists() do
      {:ok, _} -> bucket
      {:error, message} -> raise message
      other -> raise other
    end
  end

  defp ensure_bucket_exists(bucket) do
    case bucket do
      :undefined ->
        {:error, "Bucket: #{bucket} not configured"}

      bucket ->
        case bucket |> ExAws.S3.head_bucket() |> ExAws.request() do
          {:error, {:http_error, 404, _}} ->
            bucket
            |> ExAws.S3.put_bucket("us-east-1")
            |> ExAws.request!()

            {:ok, :created}

          {:ok, _} ->
            {:ok, :exists}

          other ->
            other
        end
    end
  end

  defp generate_presigned_url(bucket, path, method \\ :put) do
    bucket
    |> check_bucket()

    ExAws.S3.presigned_url(ExAws.Config.new(:s3), method, bucket, path)
  end

  defp prefix, do: Secrets.prefix()
end
