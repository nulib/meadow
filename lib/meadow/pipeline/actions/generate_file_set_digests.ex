defmodule Meadow.Pipeline.Actions.GenerateFileSetDigests do
  @moduledoc """
  Action to generate the digest map for a FileSet

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils
  alias Sequins.Pipeline.Action
  use Action
  require Logger

  @actiondoc "Generate Digests for FileSet"
  @hashes [:sha256]

  def process(data, attrs),
    do: process(data, attrs, ActionStates.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(%{file_set_id: file_set_id}, _attributes, _) do
    file_set = FileSets.get_file_set!(file_set_id)
    ActionStates.set_state!(file_set, __MODULE__, "started")

    try do
      Logger.info("Generating digests for #{file_set.id}")

      hashes =
        file_set.metadata.location
        |> Utils.Stream.stream_from()
        |> Enum.reduce(init_hashes(), &update_hashes(&2, &1))
        |> finalize_hashes()

      {:ok, _} =
        file_set
        |> FileSets.update_file_set(%{metadata: %{digests: hashes}})

      ActionStates.set_state!(file_set, __MODULE__, "ok")
      :ok
    rescue
      Meadow.Utils.Stream.Timeout ->
        ActionStates.set_state!(file_set, __MODULE__, "pending")
        :retry

      e ->
        ActionStates.set_state!(file_set, __MODULE__, "error", Exception.message(e))
        {:error, Exception.message(e)}
    end
  end

  defp init_hashes do
    Enum.map(@hashes, fn type -> :crypto.hash_init(type) end)
  end

  defp update_hashes(states, chunk) do
    states
    |> Enum.map(fn state -> :crypto.hash_update(state, chunk) end)
  end

  defp finalize_hashes(states) do
    @hashes
    |> Enum.zip(
      states
      |> Enum.map(fn state ->
        :crypto.hash_final(state)
        |> Base.encode16()
        |> String.downcase()
      end)
    )
    |> Enum.into(%{})
  end
end
