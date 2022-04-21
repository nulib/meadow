defmodule Mix.Tasks.Meadow.Elasticsearch.Setup do
  @moduledoc """
  Build elasticsearch index for the dev environment if it does not exist
  """
  use Mix.Task

  alias Meadow.Utils.Elasticsearch.RetryAPI
  alias Mix.Tasks.Elasticsearch

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    RetryAPI.configure()
    Logger.info("Creating Elasticsearch index")
    Elasticsearch.Build.run(~w|meadow --existing --cluster Meadow.ElasticsearchCluster|)
  end
end

defmodule Mix.Tasks.Meadow.Elasticsearch.Clear do
  @moduledoc """
  Clear the elasticsearch meadow and shared_links indices
  """
  use Mix.Task

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    with url <- Application.get_env(:meadow, Meadow.ElasticsearchCluster) |> Keyword.get(:url) do
      Logger.info("Clearing data from meadow index")
      Elastix.Document.delete_matching(url, "meadow", %{query: %{match_all: %{}}})

      Logger.info("Clearing data from shared_links index")

      Elastix.Document.delete_matching(url, "shared_links", %{
        query: %{match: %{"target_index.keyword": "meadow"}}
      })
    end
  end
end
