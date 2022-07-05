defmodule Meadow.Utils.Hush.Transformer.Cast do
  @moduledoc """
  Type casting Hush transformer that is more flexible than Hush's built-in Cast
  """

  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :cast
  def key, do: :cast

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(type, value) do
    cast!(type, value)
  end

  defp cast!(_, nil), do: {:ok, nil}
  defp cast!(:binary, value), do: {:ok, to_string(value)}

  defp cast!(type, value) do
    {:ok, cast!(type_of(value), type, value)}
  rescue
    err in ArgumentError -> {:error, err}
  end

  defp cast!(from, from, value), do: value
  defp cast!(:binary, :atom, value), do: value |> String.to_existing_atom()
  defp cast!(:binary, :boolean, value), do: value == "true"
  defp cast!(:binary, :charlist, value), do: value |> String.to_charlist()
  defp cast!(:binary, :float, value), do: value |> String.to_float()
  defp cast!(:binary, :integer, value), do: value |> String.to_integer()
  defp cast!(:integer, :float, value), do: value * 1.0

  defp cast!(_, to, value), do: cast!(:binary, to, to_string(value))

  defp type_of(value) when is_atom(value), do: :atom
  defp type_of(value) when is_binary(value), do: :binary
  defp type_of(value) when is_boolean(value), do: :boolean
  defp type_of(value) when is_float(value), do: :float
  defp type_of(value) when is_integer(value), do: :integer

  defp type_of(value) when is_list(value) do
    if Enum.all?(value, &(is_integer(&1) && (0 <= &1 and &1 <= 255))), do: :charlist, else: :list
  end
end
