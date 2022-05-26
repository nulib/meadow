defmodule Meadow.Data.Indexer do
  @moduledoc """
  Indexes individual structs into Elasticsearch, preloading if necessary.
  """
  use Meadow.Utils.Logging

  alias Meadow.Data.IndexTimes
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.SearchIndex
  alias Meadow.SearchIndex.DiffStore, as: Store

  require Logger

  def hot_swap do
    # case Elasticsearch.Index.hot_swap(Meadow.ElasticsearchCluster, index()) do
    #  {:error, errors} when is_list(errors) ->
    #    Enum.each(errors, fn error ->
    #      Logger.warn(error.message)
    #      Meadow.Error.report(error, Elasticsearch.Index, [])
    #    end)
    #
    #    {:error, errors}
    #
    #  {:error, error} ->
    #    Logger.warn(error.message)
    #    Meadow.Error.report(error, Elasticsearch.Index, [])
    #    {:error, error}
    #
    #  other ->
    #    other
    # end
  end

  def synchronize_index(versions \\ :all) do
    with_log_metadata module: __MODULE__ do
      [:deleted, FileSet, Work, Collection]
      |> Enum.each(&synchronize_schema(&1, versions))

      index_configs(versions)
      |> Enum.each(fn index_config ->
        SearchIndex.refresh(index_config[:name])
      end)
    end
  end

  def reindex_all!(versions \\ :all) do
    IndexTimes.reset_all!()
    synchronize_index(versions)
  end

  def synchronize_schema(schema, versions \\ :all) do
    case schema |> synchronize_chunk(versions) do
      :ok -> synchronize_schema(schema)
      :halt -> :ok
    end
  end

  defp synchronize_chunk(schema, versions) do
    case schema |> Store.retrieve() do
      [] ->
        :halt

      records ->
        index_configs(versions)
        |> Enum.each(fn index ->
          records
          |> Stream.map(&encode!(&1, schema, index))
          |> upload()
          |> Stream.run()
        end)
    end
  end

  def encode!(id, :deleted, index) do
    %{delete: %{_index: index[:name], _id: id}}
    |> json_encode()
  end

  def encode!(indexable, schema, index) do
    type = schema |> Module.split() |> List.last() |> to_string()

    [
      %{
        index: %{
          _index: index[:name],
          _id: indexable.id,
          pipeline: "meadow-v#{index[:version]}-#{type}"
        }
      },
      %{original: indexable |> SearchIndex.Document.encode()}
    ]
    |> Enum.map_join("\n", &json_encode/1)
  end

  def upload(stream) do
    with config <- config() do
      stream
      |> Stream.chunk_every(config[:bulk_page_size])
      |> Stream.intersperse(config[:bulk_wait_interval])
      |> Stream.each(&upload_batch(&1))
    end
  end

  defp upload_batch(wait_interval) when is_integer(wait_interval),
    do: :timer.sleep(wait_interval)

  defp upload_batch(docs) do
    bulk_document = docs |> Enum.join("\n")

    SearchIndex.put("/_bulk", "#{bulk_document}\n")
    |> extract_results()
    |> after_upload_batch(bulk_document)
  end

  defp extract_results({:ok, %{body: results}}) do
    {:ok,
     cond do
       Map.get(results, "errors", false) ->
         results

       results
       |> Map.get("items")
       |> Enum.any?(fn item ->
         Map.values(item) |> get_in([Access.at(0), "error"])
       end) ->
         results |> Map.put("errors", true)

       true ->
         results
     end}
  end

  defp extract_results({:error, _} = response), do: response

  defp after_upload_batch(
         {:ok, %{"errors" => true, "items" => items} = results},
         bulk_document
       ) do
    Enum.filter(items, &(Map.values(&1) |> get_in([Access.at(0), "error"])))
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
    Application.get_env(:meadow, Meadow.SearchIndex)
  end

  defp index_configs(:all), do: config() |> Keyword.get(:indexes, [])

  defp index_configs(versions) do
    index_configs(:all)
    |> Enum.filter(fn index_config -> Enum.member?(versions, index_config[:version]) end)
  end

  defp json_encode(val) do
    Application.get_env(:meadow, Meadow.SearchIndex)
    |> Keyword.get(:json_encoder, Jason)
    |> apply(:encode!, [val])
  end
end
