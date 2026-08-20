defmodule Meadow.Data.Schemas.MultiValued do
  @moduledoc """
  Casting for repeating metadata fields stored as child rows.

  `cast_entries/3` normalizes the incoming list (bare strings become entry
  params), reattaches stable ids to id-less items whose natural key exactly
  matches a current row (each row claimed at most once, in list order, so
  re-sending an unchanged list never remints ids), rejects echoed ids that do
  not belong to the field, and then hands the list to `Ecto.Changeset.cast_assoc/3`
  with `on_replace: :delete` so Ecto inserts, updates and deletes the rows.
  There is no positional or fuzzy matching: a changed value without its id is
  new content.
  """

  import Ecto.Changeset
  alias Ecto.Association.NotLoaded

  @doc """
  Options:
    * `:with` - arity-3 changeset function `(struct, params, position)` (required)
    * `:key` - natural key function applied to entry params and existing rows (required)
    * `:normalize` - function turning one incoming item into entry params (default: maps pass through)
    * `:expand` - function turning the whole incoming value (e.g. a `%{kind => value}` map)
      into a list of items before normalization (default: lists pass through)
  """
  def cast_entries(%Ecto.Changeset{} = changeset, field, opts) do
    with_fun = Keyword.fetch!(opts, :with)
    key_fun = Keyword.fetch!(opts, :key)
    normalize = Keyword.get(opts, :normalize, &identity_params/1)
    expand = Keyword.get(opts, :expand, &identity_params/1)

    case fetch_param(changeset.params, field) |> expand_param(expand) do
      :error ->
        changeset

      {:ok, nil} ->
        changeset |> put_param(field, []) |> cast_assoc(field, with: with_fun)

      {:ok, items} when is_list(items) ->
        existing = existing_entries(changeset.data, field)

        normalized =
          items |> Enum.map(normalize) |> Enum.reject(&is_nil/1) |> Enum.map(&atomize/1)

        case rehydrate(normalized, existing, key_fun) do
          {:ok, rehydrated} ->
            changeset |> put_param(field, rehydrated) |> cast_assoc(field, with: with_fun)

          {:error, message} ->
            add_error(changeset, field, message)
        end

      {:ok, _other} ->
        add_error(changeset, field, "is invalid")
    end
  end

  @doc """
  Reattach ids: items echoing an id keep it (if it belongs to `existing`);
  id-less items claim the id of the first unclaimed existing row with the same
  natural key. Returns `{:error, message}` for foreign or duplicate ids.
  """
  def rehydrate(items, existing, key_fun) do
    existing_ids = MapSet.new(existing, & &1.id)
    echoed = items |> Enum.map(&Map.get(&1, :id)) |> Enum.reject(&is_nil/1)

    cond do
      Enum.any?(echoed, &(not MapSet.member?(existing_ids, &1))) ->
        {:error, "contains an id that does not belong to this field"}

      length(Enum.uniq(echoed)) != length(echoed) ->
        {:error, "contains a duplicate id"}

      true ->
        echoed_set = MapSet.new(echoed)

        available =
          existing
          |> Enum.reject(&MapSet.member?(echoed_set, &1.id))
          |> Enum.group_by(key_fun, & &1.id)

        {rehydrated, _} = Enum.map_reduce(items, available, &claim(&1, &2, key_fun))
        {:ok, rehydrated}
    end
  end

  # An id-less item takes the first unclaimed existing id with its natural key
  defp claim(%{id: id} = item, available, _key_fun) when not is_nil(id), do: {item, available}

  defp claim(item, available, key_fun) do
    key = key_fun.(item)

    case Map.get(available, key) do
      [id | rest] -> {Map.put(item, :id, id), Map.put(available, key, rest)}
      _ -> {item, available}
    end
  end

  defp expand_param(:error, _expand), do: :error
  defp expand_param({:ok, nil}, _expand), do: {:ok, nil}
  defp expand_param({:ok, value}, expand), do: {:ok, expand.(value)}

  defp existing_entries(%{__meta__: %{state: :built}}, _field), do: []

  defp existing_entries(data, field) do
    case Map.get(data, field) do
      %NotLoaded{} ->
        raise "attempting to cast #{field} on #{inspect(data.__struct__)} before it was preloaded"

      list when is_list(list) ->
        list

      _ ->
        []
    end
  end

  defp fetch_param(params, field) do
    cond do
      Map.has_key?(params, to_string(field)) -> {:ok, Map.get(params, to_string(field))}
      Map.has_key?(params, field) -> {:ok, Map.get(params, field)}
      true -> :error
    end
  end

  # Ecto rejects mixed-key param maps, and the top-level params map may be
  # either style, so the normalized list is always stored under the string key
  defp put_param(%{params: params} = changeset, field, value) do
    params = params |> Map.delete(field) |> Map.put(to_string(field), value)
    %{changeset | params: params}
  end

  defp identity_params(%{} = map), do: map
  defp identity_params(other), do: other

  # Entry params are atom-keyed so the same key style reaches every child
  # changeset; unknown string keys are dropped rather than raising
  defp atomize(%{__struct__: _} = struct), do: struct

  defp atomize(%{} = map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} -> {key, value}
    end)
  rescue
    ArgumentError ->
      map
      |> Enum.reject(fn {key, _} -> is_binary(key) and not known_key?(key) end)
      |> Map.new(fn
        {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
        {key, value} -> {key, value}
      end)
  end

  defp atomize(other), do: other

  defp known_key?(key) do
    _ = String.to_existing_atom(key)
    true
  rescue
    ArgumentError -> false
  end
end
