defmodule Meadow.Utils.MapList do
  @moduledoc """
  Functions for manipulating lists of maps (or structs)
  """

  @doc """
  Gets the `value` for a specific `key_name => key` in `list_of_maps`
  """
  def get(list_of_maps, key_name, value_name, key) do
    case list_of_maps
         |> Enum.find(fn map -> String.to_atom(map |> Map.get(key_name)) === key end) do
      nil -> nil
      other -> Map.get(other, value_name)
    end
  end

  @doc """
  Merges new values into a map list
  """
  def merge(list_of_maps, key_name, value_name, new_values) do
    new_values
    |> Enum.reduce(list_of_maps, fn {key, value}, result ->
      result |> put(key_name, value_name, key, value)
    end)
  end

  @doc """
  Puts the given `value_name => value` under `key_name => key` in `list_of_maps`
  """
  def put(list_of_maps, key_name, value_name, key, value) do
    case list_of_maps
         |> Enum.with_index()
         |> Enum.find(fn {map, _} -> String.to_atom(map |> Map.get(key_name)) === key end) do
      {nil, _} ->
        list_of_maps ++ [%{key_name => key, value_name => value}]

      {found, index} ->
        list_of_maps |> List.replace_at(index, found |> Map.put(value_name, value))
    end
  end
end
