defmodule Meadow.Batches do
  @moduledoc """
  Meadow batch context
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.{Indexer, Works}
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo

  require Logger

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a
  @uncontrolled_fields ~w(abstract alternate_title box_name box_number caption catalog_key citation
                          description folder_name folder_number keywords notes terms_of_use
                          physical_description_material physical_description_size provenance publisher
                          related_material rights_holder scope_and_contents series source table_of_contents title)a

  def batch_update(query, delete, add) do
    delete = if is_nil(delete), do: %{}, else: delete

    add =
      cond do
        is_nil(add) -> %{descriptive_metadata: %{}}
        is_nil(add |> Map.get(:descriptive_metadata)) -> Map.put(add, :descriptive_metadata, %{})
        true -> add
      end

    Meadow.Repo.transaction(
      fn ->
        process_updates(query, delete, add)
        Indexer.synchronize_index()
      end,
      timeout: :infinity
    )
  end

  defp apply_changes([], _delete, _add), do: []

  defp apply_changes(work_ids, delete, add) do
    @controlled_fields
    |> Enum.each(fn field ->
      apply_changes(
        work_ids,
        field,
        get_in(delete, [field]),
        get_in(add, [:descriptive_metadata, field])
      )
    end)

    @uncontrolled_fields
    |> Enum.each(fn field ->
      case add |> Map.get(:descriptive_metadata) |> Map.get(field, :not_present) do
        :not_present ->
          :noop

        value ->
          from(w in Work, where: w.id in ^work_ids)
          |> Works.replace_uncontrolled_value(:descriptive_metadata, to_string(field), value)
          |> Repo.update_all([])
      end
    end)

    case add |> Map.get(:collection_id, :not_present) do
      :not_present ->
        :noop

      value ->
        from(w in Work, where: w.id in ^work_ids)
        |> Repo.update_all(
          set: [
            collection_id: value,
            updated_at: DateTime.utc_now()
          ]
        )
    end

    work_ids
  end

  defp apply_changes(_work_ids, _field, nil, nil), do: :noop
  defp apply_changes(_work_ids, _field, [], nil), do: :noop
  defp apply_changes(_work_ids, _field, nil, []), do: :noop
  defp apply_changes(_work_ids, _field, [], []), do: :noop

  defp apply_changes(work_ids, field, delete, add) do
    delete = prepare_data(delete)
    add = prepare_data(add)

    Logger.debug(
      "Deleting #{inspect(delete)} and adding #{inspect(add)} to descriptive_metadata.#{field} on #{
        length(work_ids)
      } works"
    )

    from(w in Work, where: w.id in ^work_ids)
    |> Works.replace_controlled_value(:descriptive_metadata, to_string(field), delete, add)
    |> Repo.update_all([])
  end

  defp prepare_data(nil), do: []

  defp prepare_data(data) when is_list(data),
    do: Enum.map(data, fn entry -> Map.put(entry, :role, Map.get(entry, :role, nil)) end)

  defp prepare_data(data), do: prepare_data([data])

  defp process_updates({:ok, %{"hits" => %{"hits" => []}}}, _delete, _add) do
    {:ok, :noop}
  end

  defp process_updates({:ok, %{"_scroll_id" => scroll_id, "hits" => hits}}, delete, add) do
    hits
    |> Map.get("hits")
    |> Enum.map(&Map.get(&1, "_id"))
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
