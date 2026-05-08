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

    Mix.Task.run("ecto.rollback", ["--all"])
    Mix.Task.run("ecto.migrate")
    Mix.Task.run("meadow.search.clear")
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

defmodule Mix.Tasks.Meadow.BackfillAnnotationContent do
  @moduledoc """
  Backfill annotation content from S3 into the database content column.

  Reads all completed file_set_annotations that have an s3_location but no content,
  fetches the content from S3, and writes it to the content column.

  Run this after deploying the add_content_to_file_set_annotations migration
  and before deploying the code that removes s3_location.
  """
  use Mix.Task

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSetAnnotation
  alias Meadow.Repo

  import Ecto.Query

  @shortdoc "Backfill annotation content from S3 to DB"

  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    annotations =
      from(a in FileSetAnnotation,
        where: a.status == "completed" and not is_nil(a.s3_location) and is_nil(a.content)
      )
      |> Repo.all()

    total = length(annotations)
    Mix.shell().info("Backfilling #{total} annotations...")

    {ok, err} =
      annotations
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0}, fn {annotation, i}, {ok, err} ->
        case fetch_and_store(annotation) do
          :ok ->
            Mix.shell().info("[#{i}/#{total}] #{annotation.id} ok")
            {ok + 1, err}

          {:error, reason} ->
            Mix.shell().error("[#{i}/#{total}] #{annotation.id} failed: #{inspect(reason)}")
            {ok, err + 1}
        end
      end)

    Mix.shell().info("Done. #{ok} succeeded, #{err} failed.")

    if err > 0,
      do: Mix.shell().error("Re-run to retry failed annotations.")
  end

  defp fetch_and_store(%FileSetAnnotation{s3_location: s3_location} = annotation) do
    %URI{host: bucket, path: "/" <> key} = URI.parse(s3_location)

    case ExAws.S3.get_object(bucket, key) |> ExAws.request() do
      {:ok, %{body: body}} ->
        case FileSets.update_annotation(annotation, %{content: body}) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
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
          pyramid_location = FileSets.pyramid_uri_for(file_set)

          file_set
          |> FileSet.changeset(%{derivatives: %{pyramid_tiff: pyramid_location}})
          |> Repo.update()
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end
end
