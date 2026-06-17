defmodule Mix.Tasks.Meadow.ArchivesSpace.Import do
  @moduledoc """
  Imports an ArchivesSpace resource (finding aid) into Meadow

  Creates a linked Meadow collection for the resource and a linked,
  unpublished work for each archival object at the requested levels of
  description. See `Meadow.ArchivesSpace.Importer` for details.

  ## Usage

      mix meadow.archives_space.import /repositories/2/resources/123 [options]

  ## Options

    * `--levels` - comma-separated archival object levels to import
      (default: `file,item`)
    * `--accession-prefix` - prefix for generated accession numbers
      (default: `aspace:`)

  ## Examples

      mix meadow.archives_space.import /repositories/2/resources/123
      mix meadow.archives_space.import /repositories/2/resources/123 --levels item
  """
  use Mix.Task

  alias Meadow.ArchivesSpace.Importer

  require Logger

  @shortdoc "Import an ArchivesSpace resource into Meadow"
  @switches [levels: :string, accession_prefix: :string]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, strict: @switches) do
      {opts, [resource_uri], []} ->
        resource_uri
        |> Importer.import_resource(importer_opts(opts))
        |> report()

      {_, _, invalid} when invalid != [] ->
        Mix.raise("Invalid options: #{inspect(invalid)}")

      _ ->
        Mix.raise("Usage: mix meadow.archives_space.import RESOURCE_URI [options]")
    end
  end

  defp importer_opts(opts) do
    opts
    |> Enum.map(fn
      {:levels, levels} -> {:levels, String.split(levels, ",", trim: true)}
      other -> other
    end)
  end

  defp report({:ok, summary}) do
    Mix.shell().info("""
    Imported into collection "#{summary.collection.title}" (#{summary.collection.id})
      Works created: #{length(summary.created)}
      Skipped (already linked or filtered by level): #{length(summary.skipped)}
      Errors: #{length(summary.errors)}
    """)

    Enum.each(summary.errors, fn {uri, reason} ->
      Mix.shell().error("  #{uri}: #{reason}")
    end)

    if summary.errors != [], do: exit({:shutdown, 1})
  end

  defp report({:error, reason}) do
    Mix.raise("Import failed: #{inspect(reason)}")
  end
end
