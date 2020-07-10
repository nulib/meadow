defmodule Meadow.Data.Indexer do
  @moduledoc """
  Indexes individual structs into Elasticsearch, preloading if necessary.
  """
  alias Meadow.Data.IndexTimes
  alias Meadow.Data.Schemas.{Collection, FileSet, IndexTime, Work}
  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.ElasticsearchDiffStore, as: Store
  alias Meadow.Repo

  import Ecto.Query

  @index :meadow

  def synchronize_index do
    [:deleted, FileSet, Work, Collection]
    |> Enum.each(&synchronize_schema/1)

    Elasticsearch.Index.refresh(Cluster, to_string(@index))
  end

  def reindex_all! do
    IndexTimes.reset_all!()
    synchronize_index()
  end

  def synchronize_schema(schema) do
    Store.transaction(fn ->
      schema
      |> Store.stream()
      |> Stream.map(&encode!(&1, schema))
      |> upload()
      |> Stream.run()
    end)
  end

  def encode!(id, :deleted) do
    %{delete: %{_index: @index, _id: id}}
    |> json_encode()
  end

  def encode!(indexable, _) do
    [
      %{index: %{_index: @index, _id: indexable.id}},
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

  defp upload_batch(wait_interval) when is_integer(wait_interval), do: :timer.sleep(wait_interval)

  defp upload_batch(docs) do
    bulk_document = docs |> Enum.join("\n")

    {:ok, results} = Elasticsearch.put(Cluster, "/#{@index}/_doc/_bulk", "#{bulk_document}\n")

    results
    |> Map.get("items")
    |> Enum.reduce({[], []}, fn
      %{"index" => %{"_id" => id}}, {index_ids, delete_ids} -> {[id | index_ids], delete_ids}
      %{"delete" => %{"_id" => id}}, {index_ids, delete_ids} -> {index_ids, [id | delete_ids]}
    end)
    |> set_index_time()
  end

  defp set_index_time({index_ids, delete_ids}) do
    changesets =
      index_ids
      |> Enum.map(fn id ->
        %{id: id, indexed_at: DateTime.utc_now()}
      end)

    Repo.insert_all(IndexTime, changesets,
      on_conflict: {:replace, [:indexed_at]},
      conflict_target: [:id]
    )

    from(t in IndexTime, where: t.id in ^delete_ids)
    |> Repo.delete_all()

    {index_ids, delete_ids}
  end

  defp config do
    Application.get_env(:meadow, Cluster)
  end

  defp index_config do
    config()
    |> get_in([:indexes, @index])
  end

  defp json_encode(val) do
    with mod <- config() |> get_in([:json_library]) do
      mod.encode!(val)
    end
  end
end
