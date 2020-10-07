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

  def batch_update(query, delete, add, replace) do
    Meadow.Repo.transaction(
      fn ->
        process_updates(query, delete, add, replace)
        Indexer.synchronize_index()
      end,
      timeout: :infinity
    )
  end

  # Apply sets of controlled field deletes/adds to a batch of works

  defp apply_controlled_field_changes([], _delete, _add), do: []

  defp apply_controlled_field_changes(work_ids, delete, nil),
    do: apply_controlled_field_changes(work_ids, delete, %{descriptive_metadata: %{}})

  defp apply_controlled_field_changes(work_ids, delete, add) do
    @controlled_fields
    |> Enum.each(fn field ->
      apply_controlled_field_changes(
        work_ids,
        field,
        get_in(delete, [field]),
        get_in(add, [:descriptive_metadata, field])
      )
    end)

    work_ids
  end

  defp apply_controlled_field_changes(work_ids, _field, nil, nil), do: work_ids
  defp apply_controlled_field_changes(work_ids, _field, [], nil), do: work_ids
  defp apply_controlled_field_changes(work_ids, _field, nil, []), do: work_ids
  defp apply_controlled_field_changes(work_ids, _field, [], []), do: work_ids

  defp apply_controlled_field_changes(work_ids, field, delete, add) do
    delete = prepare_controlled_field_list(delete)
    add = prepare_controlled_field_list(add)

    from(w in Work, where: w.id in ^work_ids)
    |> Works.replace_controlled_value(
      :descriptive_metadata,
      to_string(field),
      delete,
      add
    )
    |> Repo.update_all([])

    work_ids
  end

  # Make sure all controlled field lists are lists, and that each value has a role

  defp prepare_controlled_field_list(nil), do: []

  defp prepare_controlled_field_list(data) when is_list(data),
    do: Enum.map(data, fn entry -> Map.put(entry, :role, Map.get(entry, :role, nil)) end)

  defp prepare_controlled_field_list(data), do: prepare_controlled_field_list([data])

  # Apply sets of controlled field adds/replacements to a batch of works

  defp apply_uncontrolled_field_changes([], _add, _replace), do: []

  defp apply_uncontrolled_field_changes(work_ids, add, replace) do
    add = if is_nil(add), do: %{}, else: add
    replace = if is_nil(replace), do: %{}, else: replace

    with collection_id <- add |> Map.merge(replace) |> Map.get(:collection_id, :not_present) do
      update_collection_id(work_ids, collection_id)
      |> merge_uncontrolled_fields(add, :append)
      |> merge_uncontrolled_fields(replace, :replace)
    end
  end

  defp merge_uncontrolled_fields(work_ids, new_values, mode) do
    mergeable =
      new_values
      |> Map.get(:descriptive_metadata, %{})
      |> Enum.filter(fn {key, _} -> key not in @controlled_fields end)
      |> Enum.into(%{})

    if map_size(mergeable) > 0 do
      from(w in Work, where: w.id in ^work_ids)
      |> Works.merge_metadata_values(:descriptive_metadata, mergeable, mode)
      |> Repo.update_all([])
    end

    work_ids
  end

  defp update_collection_id(work_ids, :not_present), do: work_ids

  defp update_collection_id(work_ids, value) do
    from(w in Work, where: w.id in ^work_ids)
    |> Repo.update_all(
      set: [
        collection_id: value,
        updated_at: DateTime.utc_now()
      ]
    )

    work_ids
  end

  # Iterate over the Elasticsearch scroll and apply changes to each page of work IDs.

  defp process_updates({:ok, %{"hits" => %{"hits" => []}}}, _delete, _add, _replace) do
    {:ok, :noop}
  end

  defp process_updates({:ok, %{"_scroll_id" => scroll_id, "hits" => hits}}, delete, add, replace) do
    hits
    |> Map.get("hits")
    |> Enum.map(&Map.get(&1, "_id"))
    |> apply_controlled_field_changes(delete, add)
    |> apply_uncontrolled_field_changes(add, replace)

    Meadow.ElasticsearchCluster
    |> Elasticsearch.post(
      "/_search/scroll",
      Jason.encode!(%{scroll: "1m", scroll_id: scroll_id})
    )
    |> process_updates(delete, add, replace)
  end

  defp process_updates(query, delete, add, replace) do
    query =
      Jason.decode!(query)
      |> Map.put("_source", "")
      |> Jason.encode!()

    Meadow.ElasticsearchCluster
    |> Elasticsearch.post("/meadow/_search?scroll=10m", query)
    |> process_updates(delete, add, replace)
  end
end
