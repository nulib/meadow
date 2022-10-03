defmodule Meadow.Search.Bulk do
  @moduledoc """
  Bulk indexing operations for search
  """

  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.HTTP

  def delete(ids, index) do
    ids
    |> Stream.map(&Jason.encode!(%{delete: %{_id: &1}}))
    |> upload_batches(index)
  end

  def upload(documents, index) do
    documents
    |> Stream.map(&add_header/1)
    |> upload_batches(index)
  end

  defp add_header(doc) do
    [%{index: %{_id: doc.id}}, doc]
    |> Enum.map_join("\n", &Jason.encode!/1)
  end

  defp upload_batches(bulk_documents, index) do
    bulk_documents
    |> Stream.chunk_every(SearchConfig.bulk_page_size())
    |> Stream.intersperse(SearchConfig.bulk_wait_interval())
    |> Stream.each(&upload_batch(&1, index))
    |> Stream.run()
  end

  defp upload_batch(wait_interval, _) when is_integer(wait_interval),
    do: :timer.sleep(wait_interval)

  defp upload_batch(docs, index) do
    bulk_document = docs |> Enum.join("\n")
    HTTP.post("/#{index}/_bulk", bulk_document <> "\n")
  end
end
