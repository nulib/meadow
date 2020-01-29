defmodule Mix.Tasks.Meadow.Elasticsearch.Setup do
  @moduledoc """
  Build elasticsearch index for the dev environment if it does not exist
  """
  alias Mix.Tasks

  require Logger

  def run(_) do
    Logger.info("Creating Elasticsearch index")
    Elasticsearch.Build.run(~w|meadow --existing --cluster Meadow.ElasticsearchCluster|)
  end
end
