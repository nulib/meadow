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
