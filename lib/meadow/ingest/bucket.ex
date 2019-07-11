defmodule Meadow.Ingest.Bucket do
  @moduledoc """
  Helper functions for Ingest Project s3 folder
  """

  def create_project_folder(bucket, name) do
    ensure_bucket_exists(bucket)
    ExAws.S3.put_object(bucket, "#{name}/.keep", "") |> ExAws.request()
  end

  def presigned_s3_url(bucket) do
    id = Ecto.ULID.generate()
    ensure_bucket_exists(bucket)
    path = "inventory_sheets/#{id}.csv"

    {:ok, url} =
      ExAws.S3.presigned_url(ExAws.Config.new(:s3), :put, bucket, path,
        query_params: [
          {"contentType", "binary/octet-stream"}
        ]
      )

    url
  end

  defp ensure_bucket_exists(bucket) do
    case bucket do
      :undefined ->
        {:error, "Ingest bucket not configured"}

      bucket ->
        case ExAws.S3.head_bucket(bucket) |> ExAws.request() do
          {:error, {:http_error, 404, _}} ->
            ExAws.S3.put_bucket(bucket, "us-east-1")
            |> ExAws.request!()

            {:ok, :created}

          {:ok, _} ->
            {:ok, :exists}

          other ->
            other
        end
    end
  end
end
