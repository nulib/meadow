defmodule Mix.Tasks.Meadow.Seed.Export do
  @moduledoc """
  Export images and data from Meadow to an S3 bucket.

  ## Command line options

    * `--ingest_sheets` - how many ingest sheets (with associated data) to export (default: `0`)
    * `--works` - how many non-ingest-sheet works (with associated data) to export (default: `0`)
    * `--bucket` - target S3 bucket (default: the configured Meadow uploads bucket)
    * `--prefix` - (required) S3 prefix for exported assets
    * `--skip-assets` - output data only, no preservation or pyramid files (default: `false`)
    * `--threads` - how many uploads to perform at once (default: `1`)
  """

  use Mix.Task

  alias Meadow.Seed.Export

  require Logger

  @opts [
    ingest_sheets: :integer,
    works: :integer,
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

    parsed_opts =
      with {opts, _} <- OptionParser.parse!(args, strict: @opts) do
        opts
        |> Enum.into(%{
          ingest_sheets: 0,
          works: 0,
          bucket: System.get_env("SHARED_BUCKET"),
          prefix: nil,
          skip_assets: false,
          threads: 1
        })
      end

    if missing?(parsed_opts.bucket), do: raise(ArgumentError, "Bucket is required")
    if missing?(parsed_opts.prefix), do: raise(ArgumentError, "Prefix is required")

    Logger.info("Exporting database configuration manifest")
    Export.export_manifest(parsed_opts.bucket, parsed_opts.prefix)

    Logger.info("Exporting collections and nul_authorities")
    Export.export_common(parsed_opts.bucket, parsed_opts.prefix)

    Logger.info("Exporting #{parsed_opts.ingest_sheets} ingest sheets")

    sheet_ids =
      Export.export_ingest_sheets(
        parsed_opts.ingest_sheets,
        parsed_opts.bucket,
        parsed_opts.prefix
      )

    unless parsed_opts.skip_assets do
      Export.ingest_sheet_assets(sheet_ids)
      |> Export.export_assets(parsed_opts.bucket, parsed_opts.prefix, parsed_opts.threads)
    end

    Logger.info("Exporting #{parsed_opts.works} works")

    work_ids =
      Export.export_standalone_works(parsed_opts.works, parsed_opts.bucket, parsed_opts.prefix)

    unless parsed_opts.skip_assets do
      Export.work_assets(work_ids)
      |> Export.export_assets(parsed_opts.bucket, parsed_opts.prefix, parsed_opts.threads)
    end
  rescue
    exception -> Logger.error(exception)
  end

  def missing?(value), do: is_nil(value) or value == ""
end
