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

    parsed_opts =
      with {opts, _} <- OptionParser.parse!(args, strict: @opts) do
        opts
        |> Enum.into(%{prefix: nil, threads: 1})
      end

    Import.import(parsed_opts)
  rescue
    exception -> Logger.error(Exception.message(exception))
  end
end
