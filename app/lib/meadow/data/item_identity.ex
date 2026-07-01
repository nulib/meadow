defmodule Meadow.Data.ItemIdentity do
  @moduledoc """
  The single identity rule for repeating descriptive-metadata items (identified
  free-text `ValueEntry` values, notes, and related URLs):

    * An item that echoes its stable `id` keeps that identity — the ordinary
      Ecto embedded-primary-key contract.
    * An id-less item keeps its identity when its content exactly matches a
      current item's natural key, each existing id claimed at most once, in
      list order — so re-sending an unchanged list never remints ids, and
      duplicate values pair up stably.
    * Anything else is new content and gets a fresh identity (minted downstream
      by autogenerate or `WorkDescriptiveMetadata.jsonb_value_entries/1`).

  There is deliberately no positional or fuzzy matching: a changed value that
  does not echo its id is *never* paired with a dropped item, because a wrong
  guess would fabricate provenance. The conservative failure mode is a detached
  id — the edited item reads as new content and simply carries no AI lineage —
  while the append-only provenance event log still holds the full history.

  Both write paths use this module — the `WorkDescriptiveMetadata` changeset
  and the direct-jsonb CSV bulk import — so identity behaves identically
  everywhere. Items and existing entries may be structs, atom-keyed maps, or
  string-keyed jsonb maps; ids are stamped in the item's own key style because
  Ecto rejects mixed-key params.
  """

  @doc """
  Return `items` with each id-less item stamped with the id of the existing
  entry whose natural key (per `key_fun`) exactly matches its content. Ids
  already echoed by `items` are never reassigned; each existing id is claimed
  at most once, in list order; items with no resolvable key are left untouched.
  """
  def rehydrate(items, existing, key_fun) when is_list(items) and is_list(existing) do
    echoed = items |> Enum.map(&item_id/1) |> Enum.reject(&is_nil/1) |> MapSet.new()

    available =
      existing
      |> Enum.reject(fn entry ->
        id = item_id(entry)
        is_nil(id) or MapSet.member?(echoed, id)
      end)
      |> Enum.group_by(key_fun, &item_id/1)
      |> Map.delete(nil)

    {rehydrated, _available} =
      Enum.map_reduce(items, available, fn item, avail ->
        claim(item, key_fun.(item), avail)
      end)

    rehydrated
  end

  def rehydrate(items, _existing, _key_fun), do: items

  defp claim(item, nil, available), do: {item, available}

  defp claim(item, key, available) do
    case {item_id(item), Map.get(available, key)} do
      {nil, [id | rest]} -> {put_item_id(item, id), Map.put(available, key, rest)}
      _ -> {item, available}
    end
  end

  @doc "Natural key of a free-text value item: the exact text."
  def value_key(value) when is_binary(value) and value != "", do: {:value, value}

  def value_key(item) do
    case field(item, :value) do
      value when is_binary(value) and value != "" -> {:value, value}
      _ -> nil
    end
  end

  @doc "Natural key of a note: its type id and exact text."
  def note_key(item) do
    with note when is_binary(note) <- field(item, :note),
         type_id when is_binary(type_id) <- item |> field(:type) |> field(:id) do
      {:note, type_id, note}
    else
      _ -> nil
    end
  end

  @doc "Natural key of a related URL: its label id and exact URL."
  def related_url_key(item) do
    with url when is_binary(url) <- field(item, :url),
         label_id when is_binary(label_id) <- item |> field(:label) |> field(:id) do
      {:related_url, label_id, url}
    else
      _ -> nil
    end
  end

  @doc "An item's stable id, whatever the item's shape; nil when absent or blank."
  def item_id(item) do
    case field(item, :id) do
      id when is_binary(id) and id != "" -> id
      _ -> nil
    end
  end

  # Stamp an id in the item's own key style (Ecto rejects mixed-key maps). A bare
  # string is promoted to the string-keyed jsonb ValueEntry shape.
  defp put_item_id(value, id) when is_binary(value), do: %{"id" => id, "value" => value}

  defp put_item_id(%{} = item, id) do
    if Enum.any?(Map.keys(item), &is_binary/1),
      do: Map.put(item, "id", id),
      else: Map.put(item, :id, id)
  end

  defp field(%{} = item, key) do
    case item do
      %{^key => value} -> value
      _ -> Map.get(item, Atom.to_string(key))
    end
  end

  defp field(_item, _key), do: nil
end
