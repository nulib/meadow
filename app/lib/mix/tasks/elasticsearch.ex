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
    Logger.info("Creating Elasticsearch index")
    Mix.Task.run("app.config")

    indexes =
      Application.get_env(:meadow, Meadow.ElasticsearchCluster)
      |> Keyword.get(:indexes)
      |> Map.keys()
      |> Enum.map_join(" ", &to_string/1)

    Elasticsearch.Build.run(~w|#{indexes} --existing --cluster Meadow.ElasticsearchCluster|)
    Mix.Task.run("meadow.elasticsearch.pipelines")
  end
end

defmodule Mix.Tasks.Meadow.Elasticsearch.Pipelines do
  @moduledoc """
  Build elasticsearch ingest pipelines for the dev environment if it does not exist
  """
  use Mix.Task

  alias Meadow.Data.Indexer
  alias Meadow.Utils.Elasticsearch.RetryAPI

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    RetryAPI.configure()
    Logger.info("Creating Elasticsearch ingest pipelines")
    Mix.Task.run("app.config")

    Path.wildcard("priv/elasticsearch/*/pipelines/**/*.*")
    |> Enum.sort_by(&Path.extname(&1))
    |> Enum.each(&create(&1, Path.extname(&1)))

    assign_default_pipelines()
  end

  defp create(path, ".json") do
    [filename | [pipeline_prefix | _]] = Path.split(path) |> Enum.reverse()

    environment_prefix =
      [Application.get_env(:meadow, :environment_prefix), pipeline_prefix]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("-")

    pipeline_name =
      [environment_prefix, Path.basename(filename, ".json")]
      |> Enum.join("-")
      |> String.replace("_", "-")

    body =
      File.read!(path)
      |> String.replace(pipeline_prefix, environment_prefix)

    url =
      :meadow
      |> Application.get_env(Meadow.ElasticsearchCluster)
      |> Keyword.get(:url)
      |> URI.parse()
      |> URI.merge("_ingest/pipeline/#{pipeline_name}")
      |> URI.to_string()

    Logger.info("Creating pipeline #{pipeline_name}")
    Elastix.HTTP.put(url, body, [{"Content-Type", "application/json"}], [])
  end

  defp create(path, ".groovy") do
    [filename | [pipeline_prefix | _]] = Path.split(path) |> Enum.reverse()

    environment_prefix =
      [Application.get_env(:meadow, :environment_prefix), pipeline_prefix]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("-")

    script_name =
      [environment_prefix, Path.basename(filename, ".groovy")]
      |> Enum.join("-")
      |> String.replace("_", "-")

    body =
      %{
        script: %{
          lang: "painless",
          source: File.read!(path)
        }
      }
      |> Jason.encode!()

    url =
      :meadow
      |> Application.get_env(Meadow.ElasticsearchCluster)
      |> Keyword.get(:url)
      |> URI.parse()
      |> URI.merge("_scripts/#{script_name}")
      |> URI.to_string()

    Logger.info("Creating script #{script_name}")
    Elastix.HTTP.put(url, body, [{"Content-Type", "application/json"}], [])
  end

  defp create(_, _), do: :noop

  defp assign_default_pipelines do
    Application.get_env(:meadow, Meadow.ElasticsearchCluster)
    |> Keyword.get(:indexes)
    |> Enum.each(fn {name, config} ->
      case config do
        %{default_pipeline: default_pipeline} -> assign_default_pipeline(name, default_pipeline)
        _ -> :noop
      end
    end)
  end

  defp assign_default_pipeline(index, pipeline) do
    body = %{index: %{default_pipeline: pipeline}} |> Jason.encode!()

    url =
      :meadow
      |> Application.get_env(Meadow.ElasticsearchCluster)
      |> Keyword.get(:url)
      |> URI.parse()
      |> URI.merge("#{index}/_settings")
      |> URI.to_string()

    Elastix.HTTP.put(url, body, [{"Content-Type", "application/json"}], [])
  end
end

defmodule Mix.Tasks.Meadow.Elasticsearch.Teardown do
  @moduledoc """
  Teardown the elasticsearch meadow indices, scripts and pipelines
  """
  use Mix.Task
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    Mix.Task.run("app.config")
    Logger.info("Tearing down Elasticsearch environment")

    Application.get_env(:meadow, :environment_prefix)
    |> teardown_aliases()
    |> teardown_indices()
    |> teardown_pipelines()
    |> teardown_scripts()
  end

  defp find_indices(prefix) do
    case get_metadata("metadata.indices.#{prefix}**")
         |> get_in(["metadata", "indices"]) do
      nil -> []
      indices -> indices
    end
  end

  defp teardown_aliases(prefix) do
    prefix
    |> find_indices()
    |> Enum.each(fn {index, %{"aliases" => aliases}} ->
      aliases
      |> Enum.each(fn index_alias ->
        Logger.info("Deleting alias #{index_alias} on index #{index}")
        delete("#{index}/_aliases/#{index_alias}")
      end)
    end)

    prefix
  end

  defp teardown_indices(prefix) do
    prefix
    |> find_indices()
    |> Enum.each(fn {index, _} ->
      Logger.info("Deleting index #{index}")
      delete(index)
    end)

    prefix
  end

  defp teardown_pipelines(prefix) do
    get_metadata("metadata.ingest.pipeline")
    |> get_in(["metadata", "ingest", "pipeline"])
    |> Enum.each(fn %{"id" => id} ->
      if String.starts_with?(id, prefix) do
        Logger.info("Deleting pipeline #{id}")
        delete("_ingest/pipeline/#{id}")
      end
    end)

    prefix
  end

  defp teardown_scripts(prefix) do
    case get_metadata("metadata.stored_scripts.#{prefix}**")
         |> get_in(["metadata", "stored_scripts"]) do
      nil ->
        :noop

      scripts ->
        scripts
        |> Enum.each(fn {name, _} ->
          Logger.info("Deleting script #{name}")
          delete("_scripts/#{name}")
        end)
    end

    prefix
  end

  defp delete(path) do
    Application.get_env(:meadow, Meadow.ElasticsearchCluster)
    |> Keyword.get(:url)
    |> URI.parse()
    |> URI.merge(path)
    |> Elastix.HTTP.delete!()
  end

  defp get_metadata(filter) do
    Application.get_env(:meadow, Meadow.ElasticsearchCluster)
    |> Keyword.get(:url)
    |> URI.parse()
    |> URI.merge("_cluster/state?filter_path=#{filter}")
    |> URI.to_string()
    |> Elastix.HTTP.get!()
    |> Map.get(:body)
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
