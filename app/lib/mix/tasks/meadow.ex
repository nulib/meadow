defmodule Mix.Tasks.Meadow.Reset do
  @moduledoc """
  Clear out meadow database, indices, and queues
  """
  use Mix.Task
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    Code.compiler_options(ignore_module_conflict: true)
    Mix.Task.run("app.config")

    if System.get_env("AWS_DEV_ENVIRONMENT") |> is_nil() do
      Mix.Task.run("pipeline.purge")
      Mix.Task.run("pipeline.setup")
    end

    Mix.Task.run("ecto.rollback", ["--all"])
    Mix.Task.run("ecto.migrate")
    Mix.Task.run("meadow.elasticsearch.clear")
    Mix.Task.run("meadow.seed")
  end
end

defmodule Mix.Tasks.Meadow.Seed do
  @moduledoc """
  Run database seeds
  """
  use Mix.Task
  use Meadow.Utils.Logging

  alias Meadow.ReleaseTasks

  def run([]), do: run("seeds.exs")
  def run([name | []]), do: run("seeds/#{name}.exs")

  def run([name | names]) do
    run("seeds/#{name}.exs")
    run(names)
  end

  def run(name) do
    Mix.Task.run("app.config")
    ReleaseTasks.seed(name)
  end
end

defmodule Mix.Tasks.Meadow.Processes do
  @moduledoc """
  Display a list of available processes
  """

  alias Meadow.Application.Children

  def run(_) do
    [
      {"Web processes", Children.processes("web")},
      {"Basic processes", Children.processes("basic")},
      {"Pipeline processes", Children.processes("pipeline")},
      {"Aliases", Children.processes("aliases")}
    ]
    |> Enum.map(fn {label, workers} ->
      ["#{label}:", workers |> Enum.map(fn {name, _} -> "  #{name}" end), ""]
    end)
    |> List.flatten()
    |> Enum.join("\n")
    |> String.trim()
    |> IO.puts()
  end
end

defmodule Mix.Tasks.Meadow.InitializeDerivatives do
  @moduledoc """
  Initialize derivatives map for existing image file sets
  """
  use Mix.Task

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  import Ecto.Query

  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Repo.transaction(
      fn ->
        from(f in FileSet)
        |> where(fragment("role ->> 'id' in ('A', 'X')"))
        |> where(fragment("core_metadata ->> 'mime_type' LIKE 'image/%'"))
        |> Repo.stream()
        |> Stream.each(fn file_set ->
          with pyramid_location <- FileSets.pyramid_uri_for(file_set) do
            file_set
            |> FileSet.changeset(%{derivatives: %{pyramid_tiff: pyramid_location}})
            |> Repo.update()
          end
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end
end
