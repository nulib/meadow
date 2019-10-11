defmodule Meadow.Ingest.Actions.IngestFileSet do
  @moduledoc "Start the ingest of a FileSet"

  alias Meadow.Data.{AuditEntries, FileSet}
  alias Sequins.Pipeline.Action
  use Action

  @actiondoc "Start Ingesting a FileSet"

  def process(data, attrs),
    do: process(data, attrs, AuditEntries.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Beginning ingest pipeline for FileSet #{file_set_id}")

    {result, _} =
      {FileSet, file_set_id}
      |> AuditEntries.add_entry(__MODULE__, "ok")

    result
  rescue
    err in RuntimeError -> {:error, err}
  end
end
