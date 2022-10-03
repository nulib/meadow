defmodule Mix.Tasks.Meadow.Search.Setup do
  @moduledoc """
  Build search indexes for the dev environment if it does not exist
  """
  use Mix.Task

  alias Meadow.Data.Indexer

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    Logger.info("Creating search index")
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Indexer.reindex_all()
  end
end

defmodule Mix.Tasks.Meadow.Search.Teardown do
  @moduledoc """
  Teardown the elasticsearch meadow indices
  """
  use Mix.Task
  require Logger

  alias Meadow.Search.{Alias, HTTP, Index}

  @shortdoc @moduledoc
  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.config")
    Logger.info("Tearing down search environment")

    Application.get_env(:meadow, :environment_prefix)
    |> teardown_aliases()
    |> teardown_indices()
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
        Alias.remove(index_alias, [index])
      end)
    end)

    prefix
  end

  defp teardown_indices(prefix) do
    prefix
    |> find_indices()
    |> Enum.each(fn {index, _} ->
      Logger.info("Deleting index #{index}")
      Index.delete(index)
    end)

    prefix
  end

  defp get_metadata(filter) do
    case HTTP.get("_cluster/state?filter_path=#{filter}") do
      {:ok, %{body: body, status_code: 200}} -> body
      {:ok, response} -> {:error, response}
      other -> other
    end
  end
end

defmodule Mix.Tasks.Meadow.Search.Clear do
  @moduledoc """
  Clear all indices
  """
  use Mix.Task
  alias Meadow.Search.Config, as: SearchConfig
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.config")

    with url <- SearchConfig.cluster_url(),
         shared_links_index <- Application.get_env(:meadow, :shared_links_index) do
      Logger.info("Clearing data from search indexes")

      SearchConfig.aliases()
      |> Enum.each(fn alias ->
        Elastix.Document.delete_matching(url, alias, %{query: %{match_all: %{}}})
      end)

      Logger.info("Clearing data from shared_links index")

      Elastix.Document.delete_matching(url, shared_links_index, %{
        query: %{query: %{match_all: %{}}}
      })
    end
  end
end
