defmodule Meadow.ReleaseTasks do
  @app :meadow

  def migrate do
    for repo <- repos() do
      create_storage_for(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp create_storage_for(repo) do
    IO.puts :stderr, (case repo.__adapter__.storage_up(repo.config) do
      :ok -> "The database for #{inspect repo} has been created"
      {:error, :already_up} -> "The database for #{inspect repo} has already been created"
      {:error, term} when is_binary(term) -> "The database for #{inspect repo} couldn't be created: #{term}"
      {:error, term} -> "The database for #{inspect repo} couldn't be created: #{inspect term}"
    end)
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
