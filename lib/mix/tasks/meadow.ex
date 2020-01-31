defmodule Mix.Tasks.Meadow.Buckets.Create do
  @moduledoc """
  Create all configured S3 buckets
  """
  require Logger

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
  end
end

defmodule Mix.Tasks.Meadow.Setup do
  @moduledoc """
  Set up the Meadow development environment
  """

  alias Mix.Tasks.Ecto
  alias Mix.Tasks.Meadow.{Buckets, Elasticsearch, Pipeline}

  def run(args) do
    Pipeline.Setup.run(args)
    Buckets.Create.run(args)
    Ecto.Create.run(args)
    Ecto.Migrate.run(args)
    Elasticsearch.Setup.run(args)
  end
end
