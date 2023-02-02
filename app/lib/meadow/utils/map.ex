defmodule Meadow.Utils.Map do
  @moduledoc """
  Functions for manipulating maps (or structs)
  """

  @doc """
  Replaces empty map values with nil

  Examples:

    iex> nillify_empty(%{a: %{}, b: %{}, c: %{}})
    %{a: nil, b: nil, c: nil}

    iex> nillify_empty(%{a: "value", b: %{}, c: "other value"})
    %{a: "value", b: nil, c: "other value"}

    iex> nillify_empty("")
    ** (FunctionClauseError) no function clause matching in Meadow.Utils.Map.nillify_empty/1
  """
  def nillify_empty(map) when is_map(map) do
    map
    |> Enum.map(fn
      {k, v} when map_size(v) == 0 -> {k, nil}
      other -> other
    end)
    |> Enum.into(%{})
  end
end
