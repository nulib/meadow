defmodule Meadow.Data.Indexer do
  @moduledoc """
  Indexes individual structs into Elasticsearch, preloading if necessary.
  """
  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Meadow.Data.IndexTimes
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.ElasticsearchDiffStore, as: Store

  require Logger

  def hot_swap do
    case Elasticsearch.Index.hot_swap(Meadow.ElasticsearchCluster, :meadow) do
      {:error, errors} when is_list(errors) ->
        Enum.each(errors, fn error ->
          Logger.warn(error.message)
          Meadow.Error.report(error, Elasticsearch.Index, [])
        end)

        {:error, errors}

      {:error, error} ->
        Logger.warn(error.message)
        Meadow.Error.report(error, Elasticsearch.Index, [])
        {:error, error}

      other ->
        other
    end
  end

  def synchronize_index do
    with_log_metadata module: __MODULE__ do
      [:deleted, FileSet, Work, Collection]
      |> Enum.each(&synchronize_schema/1)

      Elasticsearch.Index.refresh(Cluster, to_string(index()))
    end
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

  defp after_upload_batch({:ok, %{"errors" => true, "items" => items} = results}, bulk_document) do
    Enum.filter(items, &(&1 |> Map.values() |> List.first() |> Map.has_key?("error")))
    |> Enum.each(fn error ->
      with [%{"error" => %{"reason" => reason, "type" => type}} | _] <- Map.values(error),
           message <- "(#{type}) #{reason}" do
        Logger.warn(message)

        Meadow.Error.report(
          %Meadow.IndexerError{message: message},
          __MODULE__,
          [],
          %{document_size: bulk_document |> byte_size() |> to_string()}
        )
      end
    end)

    after_upload_batch({:ok, Map.put(results, "errors", false)}, bulk_document)
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
    Meadow.Error.report(error, __MODULE__, [])

    {0, 0}
  end

  defp set_index_time({index_ids, delete_ids}) do
    IndexTimes.change(index_ids, delete_ids) |> log_update_count()
    {index_ids, delete_ids}
  end

  defp log_update_count({add_ids, update_ids, delete_ids}) do
    "Index updates: +#{length(add_ids)} ~#{length(update_ids)} -#{length(delete_ids)}"
    |> Logger.info()
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
