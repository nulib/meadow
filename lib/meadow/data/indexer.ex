defmodule Meadow.Data.Indexer do
  @moduledoc """
  Indexes individual structs into Elasticsearch, preloading if necessary.
  """
  alias Meadow.Config
  alias Meadow.Data.IndexTimes
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.ElasticsearchDiffStore, as: Store

  require Logger

  def synchronize_index do
    [:deleted, FileSet, Work, Collection]
    |> Enum.each(&synchronize_schema/1)

    Elasticsearch.Index.refresh(Cluster, to_string(index()))
  end

  def reindex_all! do
    IndexTimes.reset_all!()
    synchronize_index()
  end

  def synchronize_schema(schema) do
    case schema |> synchronize_chunk() do
      :ok -> synchronize_schema(schema)
      :halt -> :ok
    end
  end

  defp synchronize_chunk(schema) do
    case schema |> Store.retrieve() do
      [] ->
        :halt

      records ->
        records
        |> Stream.map(&encode!(&1, schema))
        |> upload()
        |> Stream.run()
    end
  end

  def encode!(id, :deleted) do
    %{delete: %{_index: index(), _id: id}}
    |> json_encode()
  end

  def encode!(indexable, _) do
    [
      %{index: %{_index: index(), _id: indexable.id}},
      indexable |> Elasticsearch.Document.encode()
    ]
    |> Enum.map(&json_encode/1)
    |> Enum.join("\n")
  end

  def upload(stream) do
    with config <- index_config() do
      stream
      |> Stream.chunk_every(config[:bulk_page_size])
      |> Stream.intersperse(config[:bulk_wait_interval])
      |> Stream.each(&upload_batch/1)
    end
  end

  def update_mapping? do
    Meadow.Config.priv_path("elasticsearch/meadow.json")
    |> update_mapping?()
  end

  def update_mapping?(path) do
    file =
      path
      |> File.read!()
      |> Jason.decode!()

    stored =
      with {:ok, %{body: body}} <-
             Config.elasticsearch_url()
             |> Elastix.Mapping.get(to_string(index()), "_doc") do
        body |> Map.values() |> List.first()
      end

    mappings_unequal?(file, stored) or
      properties_unequal?(file, stored) or
      settings_unequal?(file)
  end

  defp all_from_a_in_b?(a, b, path) do
    case {get_in(a, path), get_in(b, path)} do
      {a_value, b_value} when is_map(a_value) ->
        a_value == Map.take(b_value, Map.keys(a_value))

      {a_value, b_value} ->
        a_value == b_value
    end
  end

  defp mappings_unequal?(file, stored) do
    not all_from_a_in_b?(file, stored, ["mappings", "_doc", "dynamic_templates"])
  end

  defp properties_unequal?(file, stored) do
    not all_from_a_in_b?(file, stored, ["mappings", "_doc", "properties"])
  end

  defp settings_unequal?(file) do
    file_settings =
      with analysis_settings <- file |> get_in(["settings", "analysis"]) do
        file
        |> get_in(["settings"])
        |> Map.delete("analysis")
        |> put_in(["index", "analysis"], analysis_settings)
      end

    stored_settings =
      with {:ok, %{body: body}} <-
             Config.elasticsearch_url()
             |> Elastix.Index.get(to_string(index())) do
        body |> Map.values() |> List.first() |> get_in(["settings"])
      end

    not all_from_a_in_b?(file_settings, stored_settings, ["index"])
  end

  defp index, do: Config.elasticsearch_index()

  defp upload_batch(wait_interval) when is_integer(wait_interval), do: :timer.sleep(wait_interval)

  defp upload_batch(docs) do
    bulk_document = docs |> Enum.join("\n")

    Elasticsearch.put(
      Cluster,
      "/#{index()}/_doc/_bulk",
      "#{bulk_document}\n"
    )
    |> after_upload_batch(bulk_document)
  end

  defp after_upload_batch({:ok, results}, _) do
    results
    |> Map.get("items")
    |> Enum.reduce({[], []}, fn
      %{"index" => %{"_id" => id}}, {index_ids, delete_ids} -> {[id | index_ids], delete_ids}
      %{"delete" => %{"_id" => id}}, {index_ids, delete_ids} -> {index_ids, [id | delete_ids]}
    end)
    |> set_index_time()
  end

  defp after_upload_batch({:error, error}, bulk_document) do
    message =
      [
        "Uploading ",
        bulk_document |> byte_size() |> to_string(),
        "-byte bulk document to Elasticsearch failed because: ",
        error |> inspect()
      ]
      |> IO.iodata_to_binary()

    Logger.warn(message)

    {0, 0}
  end

  defp set_index_time({index_ids, delete_ids}) do
    IndexTimes.change(index_ids, delete_ids) |> log_update_count()
    {index_ids, delete_ids}
  end

  defp log_update_count({add_ids, update_ids, delete_ids}) do
    Logger.info(
      "Index updates: +#{length(add_ids)} ~#{length(update_ids)} -#{length(delete_ids)}"
    )
  end

  defp config do
    Application.get_env(:meadow, Cluster)
  end

  defp index_config do
    config()
    |> get_in([:indexes, index()])
  end

  defp json_encode(val) do
    with mod <- config() |> get_in([:json_library]) do
      mod.encode!(val)
    end
  end
end
