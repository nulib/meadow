defmodule Meadow.Embeddings.Model.Stub do
  @moduledoc """
  Deterministic stand-in for the embedding model: every prompt maps to a
  unit vector derived from its hash, so equal prompts get equal vectors and
  different prompts get different ones.

  Set a failure for the calling process tree with `fail_with/1`, and inspect
  what was embedded with `prompts/0`.
  """

  @behaviour Meadow.Embeddings.Model

  alias Meadow.Embeddings.Config

  @doc "Start recording calls. Call from the test process before use."
  def start do
    case Agent.start_link(fn -> %{prompts: [], error: nil} end, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start, []}}

  @doc "Every prompt embedded since the stub was started, oldest first"
  def prompts, do: Agent.get(__MODULE__, &Enum.reverse(&1.prompts))

  @doc "Make subsequent calls return `{:error, reason}`; pass `nil` to recover"
  def fail_with(reason), do: Agent.update(__MODULE__, &%{&1 | error: reason})

  @impl true
  def embed(prompts) do
    case record(prompts) do
      nil -> {:ok, Enum.map(prompts, &vector/1)}
      reason -> {:error, reason}
    end
  end

  @impl true
  def embed_image(image) when is_binary(image) do
    case record(["image:" <> Meadow.Embeddings.Text.hash(image)]) do
      nil -> {:ok, vector(image)}
      reason -> {:error, reason}
    end
  end

  @doc "The vector the stub returns for a prompt or an image"
  def vector(prompt) do
    <<seed::32, _::binary>> = :crypto.hash(:sha256, prompt)
    position = rem(seed, Config.dimensions())
    for index <- 0..(Config.dimensions() - 1), do: if(index == position, do: 1.0, else: 0.0)
  end

  defp record(prompts) do
    if Process.whereis(__MODULE__),
      do: Agent.get_and_update(__MODULE__, &record(&1, prompts))
  end

  defp record(%{error: nil} = state, prompts),
    do: {nil, %{state | prompts: Enum.reverse(prompts) ++ state.prompts}}

  defp record(%{error: error} = state, _prompts), do: {error, state}
end
