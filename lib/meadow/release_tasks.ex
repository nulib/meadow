defmodule Meadow.ReleaseTasks do
  @moduledoc """
  Release tasks for Meadow
  """
  @app :meadow
  @elastic_search_index @app
  @modules [
    Meadow.BatchDriver,
    Meadow.Data.IndexWorker,
    Meadow.Ingest.Progress,
    Meadow.Ingest.WorkCreator,
    Meadow.Ingest.WorkRedriver
  ]

  require Logger

  def migrate do
    Logger.info("Starting Meadow")
    System.put_env("MEADOW_PROCESSES", "none")
    Application.ensure_all_started(@app)
    pause!()

    for repo <- repos() do
      Logger.info("Migrating #{repo}")
      create_storage_for(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    Logger.info("Hot swapping Elasticsearch index #{@elastic_search_index}")
    Elasticsearch.Index.hot_swap(Meadow.ElasticsearchCluster, @elastic_search_index)
  after
    resume!()
  end

  def pause! do
    Enum.each(@modules, &Meadow.IntervalTask.pause!/1)
  end

  def resume! do
    Enum.each(@modules, &Meadow.IntervalTask.resume!/1)
  end

  defp create_storage_for(repo) do
    IO.puts(
      :stderr,
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          "The database for #{inspect(repo)} has been created"

        {:error, :already_up} ->
          "The database for #{inspect(repo)} has already been created"

        {:error, term} when is_binary(term) ->
          "The database for #{inspect(repo)} couldn't be created: #{term}"

        {:error, term} ->
          "The database for #{inspect(repo)} couldn't be created: #{inspect(term)}"
      end
    )
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
