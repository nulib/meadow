defmodule Meadow.Ingest.Actions.FileSetComplete do
  @moduledoc "Mark the end of the FileSet ingest pipeline"

  alias Meadow.Data.AuditEntries
  alias SQNS.Pipeline.Action
  use Action

  def process(data, attrs),
    do: process(data, attrs, AuditEntries.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Ingest pipeline complete for FileSet #{file_set_id}")
    {result, _} = AuditEntries.add_entry(file_set_id, __MODULE__, "ok")
    result
  end
end
