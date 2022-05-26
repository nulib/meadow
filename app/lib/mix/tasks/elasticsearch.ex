defmodule Mix.Tasks.Meadow.Elasticsearch.Setup do
  @moduledoc """
  Build elasticsearch index for the dev environment if it does not exist
  """
  use Mix.Task

  alias Meadow.Data.Indexer
  alias Meadow.Utils.Elasticsearch.RetryAPI
  alias Mix.Tasks.Elasticsearch

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    RetryAPI.configure()
    System.put_env([{"MEADOW_PROCESSES", "none"}, {"MEADOW_NO_REPO", "true"}])
    Mix.Task.run("meadow.elasticsearch.ingest_pipelines.create")
    Logger.info("Creating Elasticsearch index")
    Mix.Task.run("app.config")

    Elasticsearch.Build.run(
      ~w|#{Indexer.index()} --existing --cluster Meadow.ElasticsearchCluster|
    )
  end
end

defmodule Mix.Tasks.Meadow.Elasticsearch.Clear do
  @moduledoc """
  Clear the elasticsearch meadow and shared_links indices
  """
  use Mix.Task
  alias Meadow.Data.Indexer
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    Mix.Task.run("app.config")

    with url <- Application.get_env(:meadow, Meadow.ElasticsearchCluster) |> Keyword.get(:url),
         meadow_index <- Indexer.index() |> to_string(),
         shared_links_index <- Application.get_env(:meadow, :shared_links_index) do
      Logger.info("Clearing data from meadow index")
      Elastix.Document.delete_matching(url, meadow_index, %{query: %{match_all: %{}}})

      Logger.info("Clearing data from shared_links index")

      Elastix.Document.delete_matching(url, shared_links_index, %{
        query: %{match: %{"target_index.keyword": meadow_index}}
      })
    end
  end
end

defmodule Mix.Tasks.Meadow.Elasticsearch.IngestPipelines.Create do
  @moduledoc """
  Create the elasticsearch ingest pipelines
  """
  use Mix.Task
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    Mix.Task.run("app.config")

    with base_dir <- Path.join([:code.priv_dir(:meadow), "elasticsearch", "pipelines"]),
         url <- Application.get_env(:meadow, Meadow.ElasticsearchCluster) |> Keyword.get(:url) do
      [".painless", ".json"]
      |> Enum.each(&create_all(base_dir, &1, url))
    end
  end

  defp create_all(base_dir, extension, url) do
    base_dir
    |> Path.join("**/*" <> extension)
    |> Path.wildcard()
    |> Enum.each(fn path ->
      name =
        ["meadow" | path |> Path.relative_to(base_dir) |> Path.split()]
        |> Enum.join("-")
        |> Path.basename(extension)

      create(name, path, url, extension)
    end)
  end

  defp create(name, path, url, ".painless") do
    Logger.info("Creating script #{name}")

    {"_scripts/#{name}",
     %{
       script: %{
         lang: "painless",
         source: File.read!(path)
       }
     }
     |> Jason.encode!()}
    |> put(url)
  end

  defp create(name, path, url, ".json") do
    Logger.info("Creating pipeline #{name}")

    {"_ingest/pipeline/#{name}", File.read!(path)}
    |> put(url)
  end

  defp put({path, body}, url),
    do:
      URI.parse(url)
      |> URI.merge(path)
      |> URI.to_string()
      |> Elastix.HTTP.put!(body, "content-type": "application/json")
end
