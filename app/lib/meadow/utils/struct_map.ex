defmodule Meadow.Utils.StructMap do
  @moduledoc """
  Deep-convert structs to maps
  """

  @doc """
  Deep-convert a struct to a map
  """

  def deep_struct_to_map(arg) when is_struct(arg) do
    Map.from_struct(arg) |> deep_struct_to_map()
  end

  def deep_struct_to_map(arg) when is_list(arg) do
    Enum.map(arg, &deep_struct_to_map/1)
  end

  def deep_struct_to_map(arg) when is_map(arg) do
    arg
    |> Enum.map(fn {key, value} -> {key, deep_struct_to_map(value)} end)
    |> Enum.into(%{})
  end

  def deep_struct_to_map(arg) when is_tuple(arg) do
    arg
    |> Tuple.to_list()
    |> deep_struct_to_map()
    |> List.to_tuple()
  end

  def deep_struct_to_map(arg), do: arg
end
