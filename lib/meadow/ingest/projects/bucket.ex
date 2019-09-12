defmodule Meadow.Ingest.Projects.Bucket do
  @moduledoc """
  Helper functions for Ingest Project s3 folder
  """

  def create_project_folder(bucket, name) do
    bucket
    |> check_bucket()
    |> ExAws.S3.put_object("#{name}/", "")
    |> ExAws.request()
  end

  def presigned_s3_url(bucket, method \\ :put) do
    bucket
    |> check_bucket()

    id = Ecto.ULID.generate()
    path = "inventory_sheets/#{id}.csv"

    {:ok, url} = ExAws.S3.presigned_url(ExAws.Config.new(:s3), method, bucket, path)

    url
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
        {:error, "Ingest bucket not configured"}

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
end
