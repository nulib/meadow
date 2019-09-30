defmodule Meadow.Ingest.Actions.IngestFileSet do
  @moduledoc "Start the ingest of a FileSet"

  alias Meadow.Data.AuditEntries
  alias SQNS.Pipeline.Action
  use Action

  def process(%{file_set_id: file_set_id}, _) do
    AuditEntries.add_entry!(file_set_id, __MODULE__, "started")
    Logger.info("Beginning ingest pipeline for FileSet #{file_set_id}")
    AuditEntries.add_entry!(file_set_id, __MODULE__, "ok")

    :ok
  end
end
