defmodule Meadow.Data.ItemIdentity do
  @moduledoc """
  The single identity rule for repeating descriptive-metadata items (identified
  free-text `ValueEntry` values, notes, and related URLs):

    * An item that echoes its stable `id` keeps that identity only after the
      boundary verifies that the id belongs to the same field on the same work.
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

  Work changesets, direct-jsonb CSV import, batch replacement, and plan-change
  apply (via `reconcile_proposed/4` and `reconcile_appended/3`, whose items
  carry upstream-minted ids rather than echoes) all use this module so identity
  behaves identically at untrusted boundaries. Items and
  existing entries may be structs, atom-keyed maps, or string-keyed jsonb maps;
  ids are stamped in the item's own key style because Ecto rejects mixed-key
  params.
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

  @doc """
  Rehydrate `items` only after validating every echoed id against `existing`.

  An echoed id must be a UUID owned by the current work field, and it may occur
  only once in the incoming list. This is the untrusted-boundary counterpart of
  `rehydrate/3`: callers use it for work edits, CSV imports, and batch replaces
  so a copied or duplicated id cannot attach content to another item's lineage.
  """
  def reconcile(items, existing, key_fun) when is_list(items) and is_list(existing) do
    with :ok <- validate_echoed_ids(items, existing) do
      {:ok, rehydrate(items, existing, key_fun)}
    end
  end

  def reconcile(items, _existing, _key_fun), do: {:ok, items}

  @doc """
  Reconcile proposed items whose ids were minted upstream (plan-change
  operations, where the id is assigned at the plan boundary and is therefore
  *not* an echo of a destination-field id). Content that exactly matches a
  current item's natural key adopts that item's id (each claimed at most once,
  in list order), so a proposal that re-sends an unchanged value never remints
  its identity; genuinely new content keeps its minted id, so the proposal and
  the item it creates share one id from birth. An id that does belong to the
  destination field is treated as an echo and validated exactly like
  `reconcile/3`. Malformed or duplicate ids are rejected, as is any id in
  `opts[:reject_ids]`, a `MapSet` of ids known to belong elsewhere (e.g. the
  same work's other identified fields), which a proposal must never carry. A
  minted id the caller cannot prove foreign is kept: it entered at the
  plan-change boundary, and rejecting it would orphan genuinely new content.
  """
  def reconcile_proposed(items, existing, key_fun, opts \\ [])

  def reconcile_proposed(items, existing, key_fun, opts)
      when is_list(items) and is_list(existing) do
    ids = raw_item_ids(items)
    reject_ids = Keyword.get(opts, :reject_ids) || MapSet.new()

    invalid = Enum.find(ids, &(not valid_uuid?(&1)))
    foreign = Enum.find(ids, &MapSet.member?(reject_ids, &1))

    cond do
      not is_nil(invalid) -> {:error, {:invalid_id, invalid}}
      not is_nil(foreign) -> {:error, {:foreign_id, foreign}}
      true -> do_reconcile_proposed(items, existing, key_fun)
    end
  end

  def reconcile_proposed(items, _existing, _key_fun, _opts), do: {:ok, items}

  defp do_reconcile_proposed(items, existing, key_fun) do
    existing_ids = existing |> Enum.map(&item_id/1) |> Enum.reject(&is_nil/1) |> MapSet.new()

    # Set minted (non-echoed) ids aside so exact-value rehydration can pair the
    # item's content with an existing entry first; the minted id is restored
    # only when no existing identity claims the item.
    {candidates, minted} =
      items
      |> Enum.map(&set_minted_id_aside(&1, existing_ids))
      |> Enum.unzip()

    with {:ok, rehydrated} <- reconcile(candidates, existing, key_fun) do
      restored =
        rehydrated
        |> Enum.zip(minted)
        |> Enum.map(&restore_minted_id/1)

      case duplicate_id(raw_item_ids(restored)) do
        nil -> {:ok, restored}
        id -> {:error, {:duplicate_id, id}}
      end
    end
  end

  defp set_minted_id_aside(item, existing_ids) do
    id = item_id(item)

    if is_nil(id) or MapSet.member?(existing_ids, id),
      do: {item, nil},
      else: {strip_id(item), id}
  end

  defp restore_minted_id({item, nil}), do: item

  defp restore_minted_id({item, minted_id}) do
    if item_id(item), do: item, else: put_item_id(item, minted_id)
  end

  @doc """
  Validate items appended to a field as unconditionally new content that keeps
  its upstream-minted ids (plan-change `add` operations). Every id must be a
  UUID, unused by the destination field, and unique within the list. This is
  the minted-id counterpart of `strip_ids/1`, which batch appends use when
  supplied ids carry no meaning. `opts[:reject_ids]` works as in
  `reconcile_proposed/4`.
  """
  def reconcile_appended(items, existing, opts \\ [])

  def reconcile_appended(items, existing, opts) when is_list(items) and is_list(existing) do
    ids = raw_item_ids(items)
    reject_ids = Keyword.get(opts, :reject_ids) || MapSet.new()
    existing_ids = existing |> Enum.map(&item_id/1) |> Enum.reject(&is_nil/1) |> MapSet.new()

    invalid = Enum.find(ids, &(not valid_uuid?(&1)))
    foreign = Enum.find(ids, &MapSet.member?(reject_ids, &1))
    duplicate = duplicate_id(ids)
    taken = Enum.find(ids, &MapSet.member?(existing_ids, &1))

    cond do
      not is_nil(invalid) -> {:error, {:invalid_id, invalid}}
      not is_nil(foreign) -> {:error, {:foreign_id, foreign}}
      not is_nil(duplicate) -> {:error, {:duplicate_id, duplicate}}
      not is_nil(taken) -> {:error, {:duplicate_id, taken}}
      true -> {:ok, items}
    end
  end

  def reconcile_appended(items, _existing, _opts), do: {:ok, items}

  defp raw_item_ids(items), do: items |> Enum.map(&raw_item_id/1) |> Enum.reject(&is_nil/1)

  @doc "Remove client-supplied ids from items that are unconditionally new."
  def strip_ids(items) when is_list(items), do: Enum.map(items, &strip_id/1)
  def strip_ids(items), do: items

  @doc "Human-readable validation message for a `reconcile/3` error."
  def error_message({:invalid_id, id}), do: "contains an invalid item id: #{inspect(id)}"
  def error_message({:duplicate_id, id}), do: "contains the item id more than once: #{id}"

  def error_message({:foreign_id, id}),
    do: "contains an item id that does not belong to this field: #{id}"

  defp validate_echoed_ids(items, existing) do
    ids = items |> Enum.map(&raw_item_id/1) |> Enum.reject(&is_nil/1)

    with nil <- Enum.find(ids, &(not valid_uuid?(&1))),
         nil <- duplicate_id(ids),
         existing_ids <-
           existing |> Enum.map(&item_id/1) |> Enum.reject(&is_nil/1) |> MapSet.new(),
         nil <- Enum.find(ids, &(not MapSet.member?(existing_ids, &1))) do
      :ok
    else
      id when is_binary(id) ->
        cond do
          not valid_uuid?(id) -> {:error, {:invalid_id, id}}
          Enum.count(ids, &(&1 == id)) > 1 -> {:error, {:duplicate_id, id}}
          true -> {:error, {:foreign_id, id}}
        end

      id ->
        {:error, {:invalid_id, id}}
    end
  end

  defp duplicate_id(ids) do
    ids
    |> Enum.reduce_while(MapSet.new(), fn id, seen ->
      if MapSet.member?(seen, id),
        do: {:halt, id},
        else: {:cont, MapSet.put(seen, id)}
    end)
    |> case do
      %MapSet{} -> nil
      id -> id
    end
  end

  defp valid_uuid?(id) when is_binary(id), do: match?({:ok, _}, Ecto.UUID.cast(id))
  defp valid_uuid?(_), do: false

  defp raw_item_id(item), do: field(item, :id)

  defp strip_id(%{} = item), do: item |> Map.delete(:id) |> Map.delete("id")
  defp strip_id(item), do: item

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
