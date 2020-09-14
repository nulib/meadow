defmodule Meadow.Utils.Atoms do
  @moduledoc """
  Functions for dealing with atoms
  """

  @doc """
  Convert a value to a string wiht special handling for module names
  """
  def atom_to_string(v) do
    cond do
      is_binary(v) -> v
      is_atom(v) && Code.ensure_loaded?(v) -> Module.split(v) |> Enum.join(".")
      true -> inspect(v)
    end
  end
end
