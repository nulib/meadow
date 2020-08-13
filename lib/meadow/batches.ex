defmodule Meadow.Batches do
  @moduledoc """
  Meadow batch context
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.{ControlledTerms, Indexer, Works}
  alias Meadow.Utils.StructMap

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a

  def batch_update(query, delete, add) do
    Meadow.Repo.transaction(
      fn ->
        process_updates(query, delete, add)
        Indexer.synchronize_index()
      end,
      timeout: :infinity
    )
  end

  defp apply_changes([], _delete, _add), do: []

  defp apply_changes([work | works], delete, add),
    do: [apply_changes(work, delete, add) | apply_changes(works, delete, add)]

  defp apply_changes(work, delete, add) do
    with descriptive_metadata <- Map.from_struct(work.descriptive_metadata) do
      new_descriptive_metadata =
        Enum.reduce(@controlled_fields, descriptive_metadata, fn field, result ->
          apply_changes(result, field, delete, add)
        end)

      Works.update_work(work, %{descriptive_metadata: new_descriptive_metadata})
    end
  end

  defp apply_changes(metadata, field, delete, add) do
    new_value = apply_deletes(metadata, field, delete)
    values_to_add = apply_adds(new_value, field, add)

    metadata
    |> Map.put(field, new_value ++ values_to_add)
    |> StructMap.deep_struct_to_map()
  end

  defp apply_deletes(metadata, field, delete) when map_size(delete) == 0 do
    metadata
    |> Map.get(field, [])
  end

  defp apply_deletes(metadata, field, delete) do
    values_to_delete = delete |> Map.get(field, [])

    metadata
    |> Map.get(field, [])
    |> Enum.reject(fn existing_value ->
      Enum.any?(values_to_delete, fn delete_value ->
        ControlledTerms.terms_equal?(existing_value, delete_value)
      end)
    end)
  end

  defp apply_adds(metadata, _field, add) when map_size(add) == 0, do: metadata

  defp apply_adds(metadata, field, add) do
    add
    |> Map.get(:descriptive_metadata, %{})
    |> Map.get(field, [])
    |> Enum.reject(fn add_value ->
      Enum.any?(metadata, fn existing_value ->
        ControlledTerms.terms_equal?(existing_value, add_value)
      end)
    end)
  end

  defp process_updates({:ok, %{"hits" => %{"hits" => []}}}, _delete, _add) do
    {:ok, :noop}
  end

  defp process_updates({:ok, %{"_scroll_id" => scroll_id, "hits" => hits}}, delete, add) do
    hits
    |> Map.get("hits")
    |> Enum.map(&Map.get(&1, "_id"))
    |> Works.get_works()
    |> apply_changes(delete, add)

    Meadow.ElasticsearchCluster
    |> Elasticsearch.post(
      "/_search/scroll",
      Jason.encode!(%{scroll: "1m", scroll_id: scroll_id})
    )
    |> process_updates(delete, add)
  end

  defp process_updates(query, delete, add) do
    query =
      Jason.decode!(query)
      |> Map.put("_source", "")
      |> Jason.encode!()

    Meadow.ElasticsearchCluster
    |> Elasticsearch.post("/meadow/_search?scroll=10m", query)
    |> process_updates(delete, add)
  end
end
