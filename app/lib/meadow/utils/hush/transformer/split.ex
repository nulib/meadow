defmodule Meadow.Utils.Hush.Transformer.Split do
  @moduledoc """
  Split value on a string or regex
  """
  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :split
  def key, do: :split

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform({boundary, opts}, value) when is_binary(value),
    do: {:ok, value |> String.split(boundary, opts)}

  def transform(boundary, value) when is_binary(value), do: {:ok, value |> String.split(boundary)}
  def transform(_, value), do: {:ok, value}
end
