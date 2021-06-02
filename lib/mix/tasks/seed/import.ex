defmodule Mix.Tasks.Meadow.Seed.Import do
  @moduledoc """
  Import images and data from Meadow from an S3 bucket or a directory on disk.

  ## Command line options

    * `--prefix` - (required) the location of the export, either:
      * an `s3://` URI pointing to an export directory hosted in S3
      * a `file://` URI pointing to an export directory on the local disk
      * a non-URI path to an export directory on the local disk
    * `--threads` - how many uploads to perform at once (default: `1`)
  """

  use Mix.Task

  alias Meadow.Data.Schemas.{ActionState, Collection, FileSet, Work}
  alias Meadow.Ingest.Schemas.{Progress, Project, Row, Sheet}
  alias Meadow.Repo
  alias Meadow.Seed.Import

  require Logger

  @opts [
    prefix: :string,
    threads: :integer
  ]

  @shortdoc "Import images and data from Meadow from an S3 bucket or a directory on disk"
  def run(args) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")
    Logger.configure(level: :info)

    if all_clear?() do
      parsed_opts =
        with {opts, _} <- OptionParser.parse!(args, strict: @opts) do
          opts
          |> Enum.into(%{prefix: nil, threads: 1})
        end

      prefix =
        parsed_opts
        |> Map.get(:prefix)
        |> normalize_prefix()

      Import.import_assets(prefix, parsed_opts.threads)
      Import.import(prefix)
    else
      Logger.error("Import can only be run on an empty database.")
    end
  rescue
    exception -> Logger.error(exception.message)
  end

  defp all_clear? do
    [ActionState, Collection, FileSet, Work, Progress, Project, Row, Sheet]
    |> Enum.all?(&(Repo.aggregate(&1, :count) == 0))
  end

  defp normalize_prefix("s3://" <> _ = prefix), do: prefix
  defp normalize_prefix("file://" <> path), do: normalize_prefix(path)

  defp normalize_prefix(prefix) when is_binary(prefix) do
    if File.dir?(prefix),
      do: "file://#{Path.expand(prefix)}",
      else: raise(ArgumentError, "#{prefix} is not a directory")
  end

  defp normalize_prefix(_), do: raise(ArgumentError, "Prefix is required")
end
