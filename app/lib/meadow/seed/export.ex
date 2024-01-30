defmodule Meadow.Seed.Export do
  @moduledoc """
  Functions to aid in exporting Meadow data for import into another environment
  """

  alias Ecto.Adapters.SQL
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Repo
  alias Meadow.Seed.{Migration, Queries}
  alias NimbleCSV.RFC4180, as: CSV

  import Ecto.Query

  require Logger

  @common_exports ~w(collections controlled_term_cache nul_authorities)a
  @ingest_sheet_exports ~w(ingest_sheet_projects ingest_sheets ingest_sheet_rows ingest_sheet_progress
    ingest_sheet_works ingest_sheet_file_sets ingest_sheet_action_states)a
  @standalone_exports ~w(standalone_works standalone_file_sets standalone_action_states)a

  @doc """
  Export images and data from Meadow to an S3 bucket

  ## Arguments:

  - `opts`:
    - `ingest_sheets` - CSV file with ingest sheet IDs to export in the first column (default: `nil`)
    - `works` - CSV file with standalone work IDs to export in the first column (default: `nil`)
    - `bucket` - target S3 bucket (default: the configured Meadow uploads bucket)
    - `prefix` - (required) S3 prefix for exported assets
    - `skip-assets` - output data only, no preservation or pyramid files (default: `false`)
    - `threads` - how many uploads to perform at once (default: `1`)
  """
  def export(opts) do
    opts =
      opts
      |> Enum.into(%{
        ingest_sheets: nil,
        works: nil,
        bucket: System.get_env("SHARED_BUCKET"),
        prefix: nil,
        skip_assets: false,
        threads: 1
      })
      |> Map.update(:ingest_sheets, nil, &get_ids/1)
      |> Map.update(:works, nil, &get_ids/1)

    if missing?(opts.bucket), do: raise(ArgumentError, "Bucket is required")
    if missing?(opts.prefix), do: raise(ArgumentError, "Prefix is required")

    Logger.info("Exporting database configuration manifest")
    export_manifest(opts.bucket, opts.prefix)

    Logger.info("Exporting collections and nul_authorities")
    export_common(opts.bucket, opts.prefix)

    Logger.info("Exporting #{length(opts.ingest_sheets)} ingest sheets")

    sheet_ids =
      export_ingest_sheets(
        opts.ingest_sheets,
        opts.bucket,
        opts.prefix
      )

    unless opts.skip_assets do
      ingest_sheet_assets(sheet_ids)
      |> export_assets(opts.bucket, opts.prefix, opts.threads)
    end

    Logger.info("Exporting #{length(opts.works)} works")

    work_ids =
      export_standalone_works(opts.works, opts.bucket, opts.prefix)

    unless opts.skip_assets do
      work_assets(work_ids)
      |> export_assets(opts.bucket, opts.prefix, opts.threads)
    end
  end

  def export_manifest(bucket, prefix) do
    manifest = %{last_migration_version: Migration.latest_version()} |> Jason.encode!()

    ExAws.S3.put_object(bucket, Path.join([prefix, "manifest.json"]), manifest)
    |> ExAws.request!()
  end

  def export_common(_, nil), do: raise(ArgumentError, "Export requires a prefix")

  def export_common(bucket, prefix) do
    do_export(@common_exports, bucket, prefix)
  end

  def export_ingest_sheets(_, _, nil), do: raise(ArgumentError, "Export requires a prefix")

  def export_ingest_sheets(ids, bucket, prefix) do
    do_export(ids, @ingest_sheet_exports, bucket, prefix)
  end

  def export_standalone_works(_, _, nil), do: raise(ArgumentError, "Export requires a prefix")

  def export_standalone_works(ids, bucket, prefix) do
    do_export(ids, @standalone_exports, bucket, prefix)
  end

  defp do_export(ids \\ [], file_list, bucket, prefix) do
    file_list
    |> Enum.each(fn name ->
      Logger.info("Writing #{name}")

      apply(Queries, name, [ids])
      |> dump_data()
      |> upload_dump(bucket, Path.join([prefix, to_string(name)]) <> ".csv")
    end)

    ids
  end

  def ingest_sheet_assets(ingest_sheet_ids) do
    from(w in Work,
      join: fs in FileSet,
      on: fs.work_id == w.id,
      where: w.ingest_sheet_id in ^ingest_sheet_ids,
      select: %{
        id: fs.id,
        preservation_file: fragment("?.core_metadata::jsonb -> 'location'", fs)
      }
    )
    |> Repo.all()
    |> Enum.map(fn fs ->
      Map.put(fs, :pyramid_file, FileSets.pyramid_uri_for(fs.id))
    end)
  end

  def work_assets(work_ids) do
    from(fs in FileSet,
      where: fs.work_id in ^work_ids,
      select: %{
        id: fs.id,
        preservation_file: fragment("?.core_metadata::jsonb -> 'location'", fs)
      }
    )
    |> Repo.all()
    |> Enum.map(fn fs ->
      Map.put(fs, :pyramid_file, FileSets.pyramid_uri_for(fs.id))
    end)
  end

  def export_assets(_, _, _, threads) when threads < 1,
    do: raise(ArgumentError, "Threads must be >= 1")

  def export_assets(assets, bucket, prefix, 1) do
    assets
    |> Enum.each(&upload_asset_sync(&1, bucket, prefix))
  end

  def export_assets(assets, bucket, prefix, threads) do
    assets
    |> Enum.chunk_every(threads)
    |> Enum.each(fn chunk ->
      Enum.map(chunk, &upload_asset_async(&1, bucket, prefix))
      |> Task.await_many(30_000)
    end)
  end

  defp upload_asset_async(asset, bucket, prefix) do
    Task.async(fn -> upload_asset_sync(asset, bucket, prefix) end)
  end

  defp upload_asset_sync(asset, bucket, prefix) do
    with %{preservation_file: preservation_file, pyramid_file: pyramid_file} <- asset do
      copy_asset(preservation_file, bucket, Path.join([prefix, "preservation"]))
      copy_asset(pyramid_file, bucket, Path.join([prefix, "pyramid"]))
    end
  end

  defp copy_asset(source, bucket, prefix) do
    Logger.info("Copying #{source} to s3://#{bucket}/#{prefix}/")

    with %URI{host: source_bucket, path: "/" <> source_key} <- URI.parse(source) do
      case ExAws.S3.put_object_copy(
             bucket,
             Path.join([prefix, source_key]),
             source_bucket,
             source_key,
             metadata_directive: :COPY
           )
           |> ExAws.request() do
        {:error, {:http_error, status, _}} ->
          Logger.warning("Failed to copy: HTTP error #{status}")

        {:error, message} ->
          Logger.warning("Failed to copy because: #{message}")

        other ->
          other
      end
    end
  end

  defp dump_data(queryable) do
    query = "COPY (#{interpolate_params(queryable)}) TO STDOUT WITH (FORMAT CSV, HEADER)"

    SQL.query!(Repo, query, [], timeout: :infinity)
    |> Map.get(:rows)
  end

  defp upload_dump(rows, bucket, key) do
    ExAws.S3.put_object(bucket, key, Enum.join(rows, ""))
    |> ExAws.request!()
  end

  defp interpolate_params(queryable) do
    with {sql, params} <- SQL.to_sql(:all, Repo, queryable) do
      params
      |> Enum.with_index(1)
      |> Enum.reduce(sql, fn {param, index}, acc ->
        param = Enum.map(param, &Ecto.UUID.cast!/1)
        acc |> String.replace("$#{index}", param_to_sql(param))
      end)
    end
  end

  defp param_to_sql(param) when is_list(param) do
    "ARRAY[" <> Enum.map_join(param, ", ", &param_to_sql/1) <> "]"
  end

  defp param_to_sql(param) when is_binary(param) do
    case Ecto.UUID.cast(param) do
      {:ok, result} -> "'#{result}'::uuid"
      _ -> "'#{param}'"
    end
  end

  defp param_to_sql(param), do: param

  defp missing?(value), do: is_nil(value) or value == ""

  defp get_ids(nil), do: []
  defp get_ids(""), do: []
  defp get_ids("s3://" <> _ = url), do: ids_from_csv(url)
  defp get_ids("file://" <> _ = url), do: ids_from_csv(url)
  defp get_ids("http://" <> _ = url), do: ids_from_csv(url)
  defp get_ids("https://" <> _ = url), do: ids_from_csv(url)
  defp get_ids(url), do: ids_from_csv("file://" <> url)

  defp ids_from_csv(url) do
    Meadow.Utils.Stream.stream_from(url)
    |> CSV.parse_stream(skip_headers: false)
    |> Stream.map(fn [id | _] -> id end)
    |> Enum.to_list()
  end
end
