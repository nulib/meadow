defmodule Meadow.Ingest.Actions.GenerateFileSetDigests do
  @moduledoc """
  Action to generate the digest map for a FileSet

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Data.{AuditEntries, FileSets}
  alias Meadow.Data.FileSets.FileSet
  alias Meadow.Repo
  alias Meadow.Utils
  alias SQNS.Pipeline.Action
  use Action
  require Logger

  @hashes [:sha256]

  def process(data, attrs),
    do: process(data, attrs, AuditEntries.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(%{file_set_id: file_set_id}, _attributes, _) do
    AuditEntries.add_entry!(file_set_id, __MODULE__, "started")
    file_set = FileSets.get_file_set!(file_set_id)

    try do
      Logger.info("Generating digests for #{file_set.id}")

      hashes =
        file_set.metadata.location
        |> Utils.Stream.stream_from()
        |> Enum.reduce(init_hashes(), &update_hashes(&2, &1))
        |> finalize_hashes()

      file_set
      |> FileSet.changeset(%{metadata: %{digests: hashes}})
      |> Repo.update!()

      AuditEntries.add_entry!(file_set.id, __MODULE__, "ok")
      :ok
    rescue
      e in RuntimeError ->
        AuditEntries.add_entry!(file_set.id, __MODULE__, "error", e)
        {:error, e}
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
