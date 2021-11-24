defmodule Mix.Tasks.Meadow.Buckets.Create do
  @moduledoc """
  Create all configured S3 buckets
  """
  use Mix.Task
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    Meadow.Config.buckets()
    |> Enum.each(fn bucket ->
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

    with bucket <- Meadow.Config.pyramid_bucket() do
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

      bucket |> ExAws.S3.put_bucket_policy(policy) |> ExAws.request!()
    end
  end

  defp configure_bucket_notifications(%{arn: notification_arn, buckets: buckets}) do
    notification_configuration = """
      <NotificationConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <QueueConfiguration>
          <Event>s3:ObjectCreated:*</Event>
          <Queue>#{notification_arn}</Queue>
        </QueueConfiguration>
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

defmodule Mix.Tasks.Meadow.Reset do
  @moduledoc """
  Clear out meadow database, indices, and queues
  """
  use Mix.Task
  require Logger
  alias Mix.Tasks.Ecto
  alias Mix.Tasks.Meadow.{Elasticsearch, Pipeline, Seed}

  @shortdoc @moduledoc
  def run(_) do
    Code.compiler_options(ignore_module_conflict: true)
    Pipeline.Purge.run([])
    Ecto.Rollback.run(["--all"])
    Ecto.Migrate.run([])
    Pipeline.Setup.run([])
    Elasticsearch.Clear.run([])
    Seed.run([])
  end
end

defmodule Mix.Tasks.Meadow.Seed do
  @moduledoc """
  Run database seeds
  """
  use Mix.Task
  use Meadow.Utils.Logging

  alias Meadow.ReleaseTasks

  def run([]), do: run("seeds.exs")
  def run([name | []]), do: run("seeds/#{name}.exs")

  def run([name | names]) do
    run("seeds/#{name}.exs")
    run(names)
  end

  def run(name), do: ReleaseTasks.seed(name)
end

defmodule Mix.Tasks.Meadow.Processes do
  @moduledoc """
  Display a list of available processes
  """

  alias Meadow.Application.Children

  def run(_) do
    [
      {"Web processes", Children.processes("web")},
      {"Basic processes", Children.processes("basic")},
      {"Pipeline processes", Children.processes("pipeline")},
      {"Aliases", Children.processes("aliases")}
    ]
    |> Enum.map(fn {label, workers} ->
      ["#{label}:", workers |> Enum.map(fn {name, _} -> "  #{name}" end), ""]
    end)
    |> List.flatten()
    |> Enum.join("\n")
    |> String.trim()
    |> IO.puts()
  end
end

defmodule Mix.Tasks.Meadow.InitializeDerivatives do
  @moduledoc """
  Initialize derivatives map for existing image file sets
  """
  use Mix.Task

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  import Ecto.Query

  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Repo.transaction(
      fn ->
        from(f in FileSet)
        |> where(fragment("role ->> 'id' in ('A', 'X')"))
        |> where(fragment("core_metadata ->> 'mime_type' LIKE 'image/%'"))
        |> Repo.stream()
        |> Stream.each(fn file_set ->
          with pyramid_location <- FileSets.pyramid_uri_for(file_set) do
            file_set
            |> FileSet.changeset(%{derivatives: %{pyramid_tiff: pyramid_location}})
            |> Repo.update()
          end
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end
end
