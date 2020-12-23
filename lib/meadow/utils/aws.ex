defmodule Meadow.Utils.AWS do
  @moduledoc """
  Utility functions for AWS requests and object management
  """

  def presigned_url(bucket, %{upload_type: "ingest_sheet"}) do
    generate_upload_url(bucket, "ingest_sheets/#{Ecto.UUID.generate()}.csv")
  end

  def presigned_url(bucket, %{upload_type: "file_set"}) do
    generate_upload_url(bucket, "file_sets/#{Ecto.UUID.generate()}")
  end

  def presigned_url(bucket, %{upload_type: "csv_metadata"}) do
    generate_upload_url(bucket, "csv_metadata/#{Ecto.UUID.generate()}.csv")
  end

  def create_s3_folder(bucket, name) do
    bucket
    |> check_bucket()
    |> ExAws.S3.put_object("#{name}/", "")
    |> ExAws.request()
  end

  def add_aws_signature(request, region, access_key, secret) do
    request.headers ++ generate_aws_signature(request, region, access_key, secret)
  end

  defp generate_aws_signature(request, region, access_key, secret) do
    signed_request =
      Sigaws.sign_req(
        request.url,
        method: request.method |> to_string() |> String.upcase(),
        headers: request.headers,
        body: request.body,
        service: "es",
        region: region,
        access_key: access_key,
        secret: secret
      )

    case signed_request do
      {:ok, headers, _} -> headers |> Enum.into([])
      other -> other
    end
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

  defp generate_upload_url(bucket, path, method \\ :put) do
    bucket
    |> check_bucket()

    ExAws.S3.presigned_url(ExAws.Config.new(:s3), method, bucket, path)
  end
end
