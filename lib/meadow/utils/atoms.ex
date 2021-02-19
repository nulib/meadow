defmodule Meadow.Utils.Atoms do
  @moduledoc """
  Functions for dealing with atoms
  """

  @doc """
  Convert a value to a string with special handling for module names

  Examples:

    iex> atom_to_string(Meadow.Utils.Atoms)
    "Meadow.Utils.Atoms"

    iex> atom_to_string("string")
    "string"

    iex> atom_to_string(:something_else)
    ":something_else"

    iex> atom_to_string([])
    ** (ArgumentError) argument error
  """
  def atom_to_string(v) when is_atom(v) do
    if Code.ensure_loaded?(v),
      do: Module.split(v) |> Enum.join("."),
      else: inspect(v)
  end

  def atom_to_string(v) when is_binary(v), do: v

  def atom_to_string(_), do: raise(ArgumentError)

  @doc """
  Atomize values that can be atomized.

  * Maps:
    * keys are deeply atomized
    * nested maps inside lists and tuples are atomized
    * everything else is left alone
  * Strings: converted to atoms
  * Lists: members are atomized
  * Tuples: elements are atomized
  * Everything else is left alone

  Examples:

    iex> atomize(%{"top_level" => %{"next_level" => 3, "other_level" => "leave-me-alone"}})
    %{top_level: %{next_level: 3, other_level: "leave-me-alone"}}

    iex> atomize(:atom)
    :atom

    iex> atomize("string")
    :string

    iex> atomize([:list, "of", {:various, "values", %{"map" => 4}}, 5, %{"map" => 6}])
    [:list, :of, {:various, :values, %{map: 4}}, 5, %{map: 6}]
  """
  def atomize(value, top \\ true)

  def atomize(value, top) when is_map(value) do
    Enum.map(value, fn
      {k, v} when is_map(v) -> {atomize(k), atomize(v, top)}
      {k, v} when is_list(v) or is_tuple(v) -> {atomize(k), atomize(v, false)}
      {k, v} -> {atomize(k), v}
    end)
    |> Enum.into(%{})
  end

  def atomize(value, _top) when is_atom(value), do: value
  def atomize(value, true) when is_binary(value), do: String.to_atom(value)
  def atomize(value, top) when is_list(value), do: Enum.map(value, &atomize(&1, top))

  def atomize(value, top) when is_tuple(value),
    do: Tuple.to_list(value) |> atomize(top) |> List.to_tuple()

  def atomize(value, _top), do: value
end
