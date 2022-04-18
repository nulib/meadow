defmodule Meadow.Utils.Hush.Transformer.Default do
  @moduledoc """
  Complement Hush's built-in default by operating within the transformer chain
  """

  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :default
  def key, do: :default

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(default, {:error, :not_found}), do: {:ok, default}
  def transform(_, value), do: {:ok, value}
end
