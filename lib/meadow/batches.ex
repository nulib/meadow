defmodule Meadow.Batches do
  @moduledoc """
  Meadow batch context
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.{ControlledTerms, Indexer, Works}

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a

  def batch_update(query, delete) do
    Meadow.Repo.transaction(
      fn ->
        process_updates(query, delete)
        Indexer.synchronize_index()
      end,
      timeout: :infinity
    )
  end

  defp apply_delete([], _), do: []

  defp apply_delete([work | works], delete),
    do: [apply_delete(work, delete) | apply_delete(works, delete)]

  defp apply_delete(work, delete) do
    with descriptive_metadata <- Map.from_struct(work.descriptive_metadata) do
      new_descriptive_metadata =
        Enum.reduce(@controlled_fields, descriptive_metadata, fn field, result ->
          apply_delete(result, field, delete)
        end)

      Works.update_work(work, %{descriptive_metadata: new_descriptive_metadata})
    end
  end

  defp apply_delete(metadata, field, delete) do
    values = delete |> Map.get(field, [])

    new_value =
      metadata
      |> Map.get(field, [])
      |> Enum.reject(fn existing_value ->
        Enum.any?(values, fn delete_value ->
          ControlledTerms.terms_equal?(existing_value, delete_value)
        end)
      end)
      |> Enum.map(&Map.from_struct/1)

    Map.put(metadata, field, new_value)
  end

  defp process_updates({:ok, %{"hits" => %{"hits" => []}}}, _) do
    {:ok, :noop}
  end

  defp process_updates({:ok, %{"_scroll_id" => scroll_id, "hits" => hits}}, delete) do
    hits
    |> Map.get("hits")
    |> Enum.map(&Map.get(&1, "_id"))
    |> Works.get_works()
    |> apply_delete(delete)

    Meadow.ElasticsearchCluster
    |> Elasticsearch.post(
      "/_search/scroll",
      Jason.encode!(%{scroll: "1m", scroll_id: scroll_id})
    )
    |> process_updates(delete)
  end

  defp process_updates(query, delete) do
    query =
      Jason.decode!(query)
      |> Map.put("_source", "")
      |> Jason.encode!()

    Meadow.ElasticsearchCluster
    |> Elasticsearch.post("/meadow/_search?scroll=10m", query)
    |> process_updates(delete)
  end
end
