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

  def run([]), do: run("seeds.exs")
  def run([name | []]), do: run("seeds/#{name}.exs")

  def run([name | names]) do
    run("seeds/#{name}.exs")
    run(names)
  end

  def run(name) do
    with_log_level :info do
      Ecto.Migrator.with_repo(Meadow.Repo, fn _ ->
        Path.expand("priv/repo/#{name}")
        |> Code.compile_file()
        |> Enum.each(fn {module, _} -> module.run() end)
      end)
    end
  end
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
