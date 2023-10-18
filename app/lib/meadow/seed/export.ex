defmodule Meadow.Seed.Export do
  @moduledoc """
  Functions to aid in exporting Meadow data for import into another environment
  """

  alias Ecto.Adapters.SQL
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.Schemas.Sheet
  alias Meadow.Repo
  alias Meadow.Seed.{Migration, Queries}

  import Ecto.Query

  require Logger

  @common_exports ~w(collections controlled_term_cache nul_authorities)a
  @ingest_sheet_exports ~w(ingest_sheet_projects ingest_sheets ingest_sheet_rows ingest_sheet_progress
    ingest_sheet_works ingest_sheet_file_sets ingest_sheet_action_states)a
  @standalone_exports ~w(standalone_works standalone_file_sets standalone_action_states)a
  @ingest_sheet_end_states ["file_fail", "row_fail", "completed"]

  def export_manifest(bucket, prefix) do
    manifest = %{last_migration_version: Migration.latest_version()} |> Jason.encode!()

    ExAws.S3.put_object(bucket, Path.join([prefix, "manifest.json"]), manifest)
    |> ExAws.request!()
  end

  def export_common(_, nil), do: raise(ArgumentError, "Export requires a prefix")

  def export_common(bucket, prefix) do
    export(@common_exports, bucket, prefix)
  end

  def export_ingest_sheets(_, _, nil), do: raise(ArgumentError, "Export requires a prefix")

  def export_ingest_sheets(limit, bucket, prefix) do
    from(s in Sheet, where: s.status in ^@ingest_sheet_end_states)
    |> random_ids(limit)
    |> export(@ingest_sheet_exports, bucket, prefix)
  end

  def export_standalone_works(_, _, nil), do: raise(ArgumentError, "Export requires a prefix")

  def export_standalone_works(limit, bucket, prefix) do
    from(w in Work, where: is_nil(w.ingest_sheet_id))
    |> random_ids(limit)
    |> export(@standalone_exports, bucket, prefix)
  end

  defp export(ids \\ [], file_list, bucket, prefix) do
    file_list
    |> Enum.each(fn name ->
      Logger.info("Writing #{name}")

      apply(Queries, name, [ids])
      |> dump_data()
      |> upload_dump(bucket, Path.join([prefix, to_string(name)]) <> ".csv")
    end)

    ids
  end

  defp random_ids(_, 0), do: [Ecto.UUID.generate()]

  defp random_ids(queryable, limit) do
    from(q in queryable, order_by: fragment("RANDOM()"), select: q.id, limit: ^limit)
    |> Repo.all()
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
end
