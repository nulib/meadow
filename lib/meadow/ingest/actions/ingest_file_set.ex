defmodule Meadow.Ingest.Actions.IngestFileSet do
  @moduledoc "Start the ingest of a FileSet"

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
    Logger.info("Beginning ingest pipeline for FileSet #{file_set_id}")
    {result, _} = AuditEntries.add_entry(file_set_id, __MODULE__, "ok")
    result
  rescue
    err in RuntimeError -> {:error, err}
  end
end
