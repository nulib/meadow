defmodule Meadow.ReleaseTasks do
  @moduledoc """
  Release tasks for Meadow
  """
  @app :meadow
  @elastic_search_index @app
  @modules [
    Meadow.Data.IndexWorker,
    Meadow.Ingest.Progress,
    Meadow.Ingest.ValidationNotifier,
    Meadow.Ingest.WorkCreator,
    Meadow.Ingest.WorkRedriver
  ]

  alias Ecto.Adapters.SQL
  alias Meadow.{BackgroundTask, Pipeline}
  alias Meadow.Utils.Logging

  def migrate do
    [:elasticsearch, :ex_aws, :hackney, :sequins] |> Enum.each(&Application.ensure_all_started/1)
    Pipeline.queue_config() |> Sequins.setup()

    for repo <- repos() do
      create_storage_for(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    Elasticsearch.Index.hot_swap(Meadow.ElasticsearchCluster, @elastic_search_index)
  end

  def seed, do: _seed("priv/repo/seeds.exs")
  def seed(name) when is_binary(name), do: _seed("priv/repo/seeds/#{name}.exs")
  def seed([name | []]), do: seed(name)

  def seed([name | names]) do
    seed(name)
    seed(names)
  end

  defp _seed(file) do
    Logging.with_log_level(:info, fn ->
      Path.join(Application.app_dir(:meadow), file)
      |> Code.compile_file()
      |> Enum.each(fn {module, _} -> module.run() end)
    end)
  end

  def reset! do
    Enum.each(@modules, &BackgroundTask.pause!(&1))

    for repo <- repos() do
      SQL.query!(
        repo,
        "SELECT * FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'"
      )
      |> Map.get(:rows)
      |> Enum.each(fn [_, table, _, _, _, _, _, _] ->
        SQL.query!(repo, "DROP TABLE #{table} CASCADE")
      end)
    end

    migrate()
    seed()
  after
    Enum.each(@modules, &BackgroundTask.resume!(&1))
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
