defmodule Mix.Tasks.Meadow.Buckets.Create do
  @moduledoc """
  Create all configured S3 buckets

  We need to use `Meadow.Config.Runtime.buckets()` all through thes modules
  because the runtime configuration doesn't get loaded for mix tasks
  """
  use Mix.Task
  alias Meadow.AWS.S3
  alias Meadow.Config.Runtime
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:aws_credentials, :req] |> Enum.each(&Application.ensure_all_started/1)

    buckets = Runtime.buckets()

    buckets
    |> Enum.each(fn {_, bucket} ->
      unless S3.bucket_exists?(bucket) do
        Logger.info("Creating S3 Bucket: #{bucket}")
        S3.create_bucket!(bucket)
      end
    end)

    Application.get_env(:meadow, :checksum_notification, nil)
    |> configure_bucket_notifications()

    with bucket <- Keyword.get(buckets, :preservation_bucket) do
      policy = %{
        "Statement" => [
          %{
            "Action" => ["s3:GetBucketLocation", "s3:ListBucket"],
            "Effect" => "Allow",
            "Principal" => %{"AWS" => ["*"]},
            "Resource" => ["arn:aws:s3:::#{bucket}"]
          },
          %{
            "Action" => ["s3:GetObject"],
            "Effect" => "Allow",
            "Principal" => %{"AWS" => ["*"]},
            "Resource" => ["arn:aws:s3:::#{bucket}/*"]
          }
        ],
        "Version" => "2012-10-17"
      }

      S3.put_bucket_policy(bucket, policy)
    end
  end

  defp configure_bucket_notifications(%{arn: notification_arn, buckets: buckets}) do
    configuration = %{
      "CloudFunctionConfiguration" => %{
        "Event" => ["s3:ObjectCreated:Put", "s3:ObjectCreated:CompleteMultipartUpload"],
        "CloudFunction" => notification_arn
      }
    }

    Enum.each(buckets, fn bucket ->
      Logger.info("Configuring #{bucket} for fixity notification")
      S3.put_bucket_notification_configuration(bucket, configuration)
    end)
  end

  defp configure_bucket_notifications(_), do: :noop
end

defmodule Mix.Tasks.Meadow.Buckets.Seed do
  @moduledoc """
  Add placeholder images to the pyramid bucket
  """
  use Mix.Task
  alias Meadow.AWS.S3
  alias Meadow.Config.Runtime
  require Logger

  @prefix "00/00/00/00/-0/00/0-/00/00/-0/00/0-/00/00/00/00/00/"

  @shortdoc @moduledoc
  def run(_) do
    [:aws_credentials, :req] |> Enum.each(&Application.ensure_all_started/1)

    Logger.info("Uploading placeholder images to the pyramid bucket")

    for file <- Path.wildcard("test/fixtures/placeholders/*.tif") do
      Runtime.buckets()
      |> Keyword.get(:pyramid_bucket)
      |> S3.put_object!(@prefix <> Path.basename(file), File.read!(file))
    end
  end
end

defmodule Mix.Tasks.Meadow.Buckets.Inventory do
  @shortdoc "Generate an S3-Inventory-style CSV for a bucket"
  @moduledoc """
  Usage: mix bucket.inventory BUCKET [OUTPUT.csv]
  """
  use Mix.Task

  alias NimbleCSV.RFC4180, as: CSV

  @headers ~w(Bucket Key Size LastModifiedDate StorageClass IsMultipartUploaded
              ReplicationStatus IntelligentTieringAccessTier)

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {bucket, out_path} =
      case args do
        [bucket] -> {bucket, "#{bucket}-inventory.csv"}
        [bucket, path] -> {bucket, path}
        _ -> Mix.raise("Usage: mix bucket.inventory BUCKET [OUTPUT.csv]")
      end

    client = Meadow.AWS.client(:s3)

    count =
      File.open!(out_path, [:write, :utf8], fn file ->
        IO.write(file, CSV.dump_to_iodata([@headers]))
        write_pages(client, bucket, file, nil, 0)
      end)

    Mix.shell().info("Wrote #{count} rows to #{out_path}")
  end

  defp write_pages(client, bucket, file, token, count) do
    {:ok, body, _resp} = AWS.S3.list_objects_v2(client, bucket, token)
    result = body["ListBucketResult"]

    rows = result |> Map.get("Contents") |> List.wrap() |> Enum.map(&row(bucket, &1))
    IO.write(file, CSV.dump_to_iodata(rows))
    count = count + length(rows)

    Mix.shell().info("#{count} objects...")

    if result["IsTruncated"] == "true" do
      write_pages(client, bucket, file, result["NextContinuationToken"], count)
    else
      count
    end
  end

  defp row(bucket, obj) do
    [
      bucket,
      # S3 Inventory URL-encodes keys
      URI.encode(obj["Key"], &(URI.char_unreserved?(&1) or &1 == ?/)),
      to_string(obj["Size"]),
      obj["LastModified"],
      obj["StorageClass"] || "STANDARD",
      # Multipart ETags look like "<md5>-<partcount>"
      obj["ETag"] |> String.trim("\"") |> String.contains?("-") |> to_string(),
      "COMPLETED",
      "DEEP_ARCHIVE"
    ]
  end
end
