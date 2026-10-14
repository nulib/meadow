defmodule Mix.Tasks.Meadow.PopulateFileSetSizes do
  use Mix.Task

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  alias Meadow.Utils.Stream, as: MeadowStream
  alias NimbleCSV.RFC4180, as: CSV

  import Ecto.Query

  require Logger

  @shortdoc "Populates file set sizes from a preservation bucket inventory"
  @moduledoc """
  Usage mix meadow.populate_file_set_sizes preservation_bucket_inventory.csv
  """
  def run(args) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    [inventory_file] = args
    execute(inventory_file)
  end

  def execute(inventory_file) do
    create_inventory_cache(inventory_file)

    Repo.transaction(fn ->
      from(f in FileSet, where: fragment("core_metadata->>'file_size' IS NULL"))
      |> Repo.stream()
      |> Stream.each(&update_file_set/1)
      |> Stream.run()
    end, timeout: :infinity)
  end

  defp update_file_set(file_set) do
    case :ets.lookup(:inventory_cache, file_set.core_metadata.location) do
      [{_key, file_size}] ->
        Logger.debug("Updating file set #{file_set.id} with size #{file_size}")
        FileSets.update_file_set(
          file_set,
          %{core_metadata: %{file_size: file_size}}
        )
      [] ->
        Logger.warning("File set not found in inventory cache: #{file_set.core_metadata.location}")
    end
  end

  defp create_inventory_cache(inventory_file) do
    Logger.info("Reading inventory file: #{inventory_file}")
    :ets.new(:inventory_cache, [:set, :private, :named_table])

    inventory_file = normalize_location(inventory_file)
    if not MeadowStream.exists?(inventory_file) do
      raise "Inventory file not found: #{inventory_file}"
    end

    if String.ends_with?(inventory_file, ".gz") do
      MeadowStream.stream_from(inventory_file)
      |> StreamGzip.gunzip()
    else
      MeadowStream.stream_from(inventory_file)
    end
    |> CSV.to_line_stream()
    |> CSV.parse_stream(skip_headers: true)
    |> Stream.each(fn [bucket|[key|[size|_]]] ->
      :ets.insert(:inventory_cache, {"s3://#{bucket}/#{key}", String.to_integer(size)})
    end)
    |> Stream.run()

    Logger.info("Cached #{:ets.info(:inventory_cache)[:size]} entries")
  end

  defp normalize_location("file://" <> _ = location), do: location
  defp normalize_location("s3://" <> _ = location), do: location
  defp normalize_location("http://" <> _ = location), do: location
  defp normalize_location("https://" <> _ = location), do: location
  defp normalize_location(location), do: "file://" <> Path.expand(location)
end
