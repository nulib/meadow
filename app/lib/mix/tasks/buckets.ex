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
