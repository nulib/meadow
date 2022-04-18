defmodule Meadow.Utils.Hush.Transformer.Dig do
  @moduledoc """
  Dig values out of maps as per `Kernel.get_in/2`
  """
  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :dig
  def key, do: :dig

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(path, value), do: value |> dig(path)

  defp dig({:ok, {:error, :not_found}} = result, _), do: result
  defp dig(value, []), do: {:ok, value}

  defp dig(value, [key | path]) do
    Access.get(value, key, {:ok, {:error, :not_found}}) |> dig(path)
  rescue
    _ in FunctionClauseError -> {:ok, {:error, :not_found}}
  end
end
