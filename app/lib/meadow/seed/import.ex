defmodule Meadow.Seed.Import do
  @moduledoc """
  Functions to aid in importing Meadow data exported by Meadow.Seed.Export
  """

  alias Ecto.Adapters.SQL
  alias Meadow.Config
  alias Meadow.Data.{Collections, FileSets, Indexer, Works}
  alias Meadow.Data.Schemas.{ActionState, Collection, ControlledTermCache, FileSet, Work}
  alias Meadow.Ingest.Schemas.{Progress, Project, Row, Sheet}
  alias Meadow.Repo
  alias Meadow.Seed.Migration
  alias Meadow.Utils.Stream, as: StreamUtil

  NimbleCSV.define(CSV, line_separator: "\n")

  import Ecto.Query

  require Logger

  @import_tables [
    {:collections, Collection},
    {:controlled_term_cache, ControlledTermCache},
    {:nul_authorities, NUL.Schemas.AuthorityRecord},
    {:ingest_sheet_projects, Project},
    {:ingest_sheets, Sheet},
    {:ingest_sheet_rows, Row},
    {:ingest_sheet_progress, Progress},
    {:ingest_sheet_works, Work},
    {:ingest_sheet_file_sets, FileSet},
    {:ingest_sheet_action_states, ActionState},
    {:standalone_works, Work},
    {:standalone_file_sets, FileSet},
    {:standalone_action_states, ActionState}
  ]

  @null_fields %{
    Collection => ~w(representative_work_id),
    Work => ~w(representative_file_set_id)
  }

  def import_assets("s3://" <> _ = prefix, threads) do
    import_assets(prefix, "preservation", Meadow.Config.preservation_bucket(), threads)
    import_assets(prefix, "pyramid", Meadow.Config.pyramid_bucket(), threads)
  end

  def import_assets("file://" <> _ = prefix, threads) do
    import_assets(prefix, "preservation", Meadow.Config.preservation_bucket(), threads)
    import_assets(prefix, "pyramid", Meadow.Config.pyramid_bucket(), threads)
  end

  def import_assets(prefix, _), do: raise(ArgumentError, "Unknown prefix: #{inspect(prefix)}")

  defp import_assets(_, _, _, threads) when threads < 1,
    do: raise(ArgumentError, "Threads must be >= 1")

  defp import_assets(prefix, path, bucket, 1) do
    dest_prefix = "s3://#{bucket}/"

    with source_path <- Path.join([prefix, path]) <> "/" do
      StreamUtil.list_contents(source_path)
      |> Enum.each(&import_asset_sync(&1, source_path, dest_prefix))
    end
  end

  defp import_assets(prefix, path, bucket, threads) do
    dest_prefix = "s3://#{bucket}/"

    with source_path <- Path.join([prefix, path]) <> "/" do
      StreamUtil.list_contents(source_path)
      |> Enum.chunk_every(threads)
      |> Enum.each(fn chunk ->
        Enum.map(chunk, &import_asset_async(&1, source_path, dest_prefix))
        |> Task.await_many(30_000)
      end)
    end
  end

  defp import_asset_async(source, source_prefix, dest_prefix) do
    Task.async(fn -> import_asset_sync(source, source_prefix, dest_prefix) end)
  end

  defp import_asset_sync(source, source_prefix, dest_prefix) do
    dest_key = source |> String.replace(~r(^#{source_prefix}), "")
    dest = dest_prefix <> dest_key
    Logger.info("Uploading #{source} to #{dest}")
    StreamUtil.copy(source, dest)
  end

  def disable_triggers do
    Logger.info("Disabling triggers")

    @import_tables
    |> Enum.each(fn {_name, schema} ->
      with table_name <- schema.__schema__(:source) do
        SQL.query!(Repo, "ALTER TABLE #{table_name} DISABLE TRIGGER USER")
      end
    end)
  end

  def enable_triggers do
    Logger.info("Enabling triggers")

    @import_tables
    |> Enum.each(fn {_name, schema} ->
      with table_name <- schema.__schema__(:source) do
        SQL.query!(Repo, "ALTER TABLE #{table_name} ENABLE TRIGGER USER")
      end
    end)
  end

  def import(prefix) do
    manifest =
      StreamUtil.stream_from(Path.join(prefix, "manifest.json"))
      |> Enum.into("")
      |> Jason.decode!(keys: :atoms)

    database_version = manifest |> Map.get(:last_migration_version)

    Migration.with_database_version(database_version, fn ->
      disable_triggers()

      @import_tables
      |> Enum.each(fn {name, schema} ->
        Logger.info("Importing #{name} into #{schema}")
        load(schema, Path.join([prefix, to_string(name)]) <> ".csv")
      end)

      enable_triggers()
    end)

    disable_triggers()
    Logger.info("Setting default images on works")
    ensure_representative_images()
    Logger.info("Fixing file set preservation locations")
    fix_file_set_preservation_locations()
    enable_triggers()

    Logger.info("Synchronizing index")
    Indexer.synchronize_index()
  end

  def load(schema, source) do
    with table_name <- schema.__schema__(:source),
         data <- StreamUtil.stream_from(source) |> StreamUtil.by_line(),
         [header_row] <- data |> Enum.take(1),
         headers <- header_row |> String.trim() |> String.split(","),
         stream <- data |> prepare_stream(headers, schema) do
      sql = "COPY #{table_name} (#{header_row}) FROM STDIN WITH (FORMAT CSV, NULL '')"
      Repo.transaction(fn -> Enum.into(stream, SQL.stream(Repo, sql)) end, timeout: :infinity)
    end
  end

  def ensure_representative_images do
    Repo.transaction(
      fn ->
        [Work, Collection] |> Enum.each(&ensure_representative_images/1)
      end,
      timeout: :infinity
    )
  end

  defp ensure_representative_images(Work) do
    from(w in Work, where: is_nil(w.representative_file_set_id))
    |> Repo.stream()
    |> Stream.each(&Works.set_default_representative_image!/1)
    |> Stream.run()
  end

  defp ensure_representative_images(Collection) do
    from(c in Collection, where: is_nil(c.representative_work_id))
    |> Repo.stream()
    |> Stream.each(fn collection ->
      case Works.get_works_by_collection(collection.id) do
        [] -> collection
        [work | _] -> collection |> Collections.set_representative_image(work)
      end
    end)
    |> Stream.run()
  end

  def fix_file_set_preservation_locations do
    Repo.transaction(
      fn ->
        FileSet
        |> Repo.stream()
        |> Stream.each(&update_file_set_preservation_location/1)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  defp update_file_set_preservation_location(%FileSet{} = file_set) do
    case Map.from_struct(file_set) |> update_file_set_preservation_location() do
      :noop -> :noop
      attrs -> file_set |> FileSets.update_file_set(attrs)
    end
  end

  defp update_file_set_preservation_location(%{core_metadata: %{location: location}} = file_set)
       when is_map(file_set) and is_binary(location) do
    %{core_metadata: %{location: update_location(location)}}
  end

  defp update_file_set_preservation_location(%{metadata: %{location: location}} = file_set)
       when is_map(file_set) and is_binary(location) do
    %{metadata: %{location: update_location(location)}}
  end

  defp update_file_set_preservation_location(_), do: :noop

  defp update_location(location) do
    URI.parse(location)
    |> Map.put(:host, Config.preservation_bucket())
    |> URI.to_string()
  end

  defp prepare_stream(data, headers, schema) do
    with rows <- data |> CSV.parse_stream(headers: true) do
      @null_fields
      |> Map.get(schema)
      |> do_prepare_stream(rows, headers)
      |> CSV.dump_to_stream()
      |> Stream.map(&IO.iodata_to_binary/1)
      |> Stream.reject(&(&1 == "\n"))
    end
  end

  defp do_prepare_stream(nil, rows, _), do: rows

  defp do_prepare_stream(fields, rows, headers) do
    indexes =
      fields
      |> Enum.map(fn field ->
        Enum.find_index(headers, fn header -> header == field end)
      end)

    Stream.map(rows, fn row ->
      Enum.reduce(indexes, row, &List.replace_at(&2, &1, nil))
    end)
  end
end
