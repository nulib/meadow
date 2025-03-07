defmodule Meadow.ReleaseTasks do
  @moduledoc """
  Release tasks for Meadow
  """

  alias Meadow.Config
  alias Meadow.Data.Indexer

  @app :meadow
  @modules [
    Meadow.BatchDriver,
    Meadow.Data.IndexWorker,
    Meadow.Data.ReindexWorker,
    Meadow.Ingest.Progress,
    Meadow.Ingest.WorkCreator,
    Meadow.Ingest.WorkRedriver
  ]

  use Meadow.Utils.Logging

  require Logger

  def migrate(reindex? \\ false) do
    Logger.info("Starting Meadow")
    System.put_env("MEADOW_PROCESSES", "none")
    Application.ensure_all_started(@app)
    pause!()

    for repo <- repos() do
      Logger.info("Migrating #{repo}")
      create_storage_for(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    seed("seeds.exs")

    if reindex? do
      Logger.info("Hot swapping all search indices")
      Indexer.reindex_all()
    end
  after
    resume!()
  end

  def seed(name) do
    with_log_level :info do
      Ecto.Migrator.with_repo(Meadow.Repo, fn _ ->
        Config.priv_path("repo/#{name}")
        |> Path.expand()
        |> Code.compile_file()
        |> Enum.each(fn {module, _} -> module.run() end)
      end)
    end
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
