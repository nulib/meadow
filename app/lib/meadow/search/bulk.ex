defmodule Meadow.Search.Bulk do
  @moduledoc """
  Bulk indexing operations for search
  """

  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.HTTP

  require Logger

  @retries 3

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
    bulk_document = Enum.join(docs, "\n")

    case with_retry(fn -> upload_bulk_document(index, bulk_document) end) do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.error("Bulk upload failed after #{@retries} retries. Error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp upload_bulk_document(index, bulk_document) do
    HTTP.post("/#{index}/_bulk", bulk_document <> "\n")
  end

  defp with_retry(func, remaining_tries \\ @retries, last_response \\ nil)

  defp with_retry(_, 0, last_response), do: last_response

  defp with_retry(func, remaining_tries, _) do
    with response <- func.() do
      case response do
        {:error, _} ->
          Logger.warn("Bulk upload failed. Retrying. Attempts left: #{remaining_tries - 1}")
          with_retry(func, remaining_tries - 1, response)

        other ->
          other
      end
    end
  end
end
