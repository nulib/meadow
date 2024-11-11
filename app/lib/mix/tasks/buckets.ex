defmodule Mix.Tasks.Meadow.Buckets.Create do
  @moduledoc """
  Create all configured S3 buckets

  We need to use `Meadow.Config.Runtime.buckets()` all through thes modules
  because the runtime configuration doesn't get loaded for mix tasks
  """
  use Mix.Task
  alias Meadow.Config.Runtime
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    buckets = Runtime.buckets()

    buckets
    |> Enum.each(fn {_, bucket} ->
      case ExAws.S3.head_bucket(bucket) |> ExAws.request() do
        {:error, {:http_error, 404, _}} ->
          Logger.info("Creating S3 Bucket: #{bucket}")
          ExAws.S3.put_bucket(bucket, Application.get_env(:ex_aws, :region)) |> ExAws.request!()

        _ ->
          :noop
      end
    end)

    Application.get_env(:meadow, :checksum_notification, nil)
    |> configure_bucket_notifications()

    with bucket <- Keyword.get(buckets, :preservation_bucket) do
      policy =
        %{
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
        |> Jason.encode!()

      bucket |> ExAws.S3.put_bucket_policy(policy) |> ExAws.request()
    end
  end

  defp configure_bucket_notifications(%{arn: notification_arn, buckets: buckets}) do
    notification_configuration = """
      <NotificationConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <CloudFunctionConfiguration>
          <Event>s3:ObjectCreated:Put</Event>
          <Event>s3:ObjectCreated:CompleteMultipartUpload</Event>
          <CloudFunction>#{notification_arn}</CloudFunction>
        </CloudFunctionConfiguration>
      </NotificationConfiguration>
    """

    Enum.each(buckets, fn bucket ->
      Logger.info("Configuring #{bucket} for fixity notification")

      %ExAws.Operation.S3{
        http_method: :put,
        bucket: bucket,
        resource: "notification",
        body: notification_configuration
      }
      |> ExAws.request()
    end)
  end

  defp configure_bucket_notifications(_), do: :noop
end

defmodule Mix.Tasks.Meadow.Buckets.Seed do
  @moduledoc """
  Add placeholder images to the pyramid bucket
  """
  use Mix.Task
  alias Meadow.Config.Runtime
  require Logger

  @prefix "00/00/00/00/-0/00/0-/00/00/-0/00/0-/00/00/00/00/00/"

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    Logger.info("Uploading placeholder images to the pyramid bucket")

    for file <- Path.wildcard("test/fixtures/placeholders/*.tif") do
      Runtime.buckets()
      |> Keyword.get(:pyramid_bucket)
      |> ExAws.S3.put_object(
        @prefix <> Path.basename(file),
        File.read!(file)
      )
      |> ExAws.request!()
    end
  end
end
