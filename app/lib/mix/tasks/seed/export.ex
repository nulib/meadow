defmodule Mix.Tasks.Meadow.Seed.Export do
  @moduledoc """
  Export images and data from Meadow to an S3 bucket.

  ## Command line options

    * `--ingest_sheets` - CSV file with ingest sheet IDs to export in the first column (default: `nil`)
    * `--works` - CSV file with standalone work IDs to export in the first column (default: `nil`)
    * `--bucket` - target S3 bucket (default: the configured Meadow uploads bucket)
    * `--prefix` - (required) S3 prefix for exported assets
    * `--skip-assets` - output data only, no preservation or pyramid files (default: `false`)
    * `--threads` - how many uploads to perform at once (default: `1`)
  """

  use Mix.Task

  alias Meadow.Seed.Export

  require Logger

  @opts [
    ingest_sheets: :string,
    works: :string,
    bucket: :string,
    prefix: :string,
    skip_assets: :boolean,
    threads: :integer
  ]

  @shortdoc "Export images and data from Meadow to an S3 bucket"
  def run(args) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Logger.configure(level: :info)

    with {opts, _} <- OptionParser.parse!(args, strict: @opts) do
      Export.export(opts)
    end
  rescue
    exception -> Logger.error(exception)
  end
end
