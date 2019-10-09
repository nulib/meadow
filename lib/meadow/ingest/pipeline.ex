defmodule Meadow.Ingest.Pipeline do
  @moduledoc """
  Defines the queue configuration for the ingest pipeline
  """

  def queue_config do
    [
      IngestFileSet: [],
      GenerateFileSetDigests: [IngestFileSet: [status: :ok]],
      CopyFileToPreservation: [GenerateFileSetDigests: [status: :ok]],
      UpdateIngestSheetStatus: [
        IngestFileSet: [context: :IngestSheet, status: :error],
        GenerateFileSetDigests: [context: :IngestSheet, status: :error],
        CopyFileToPreservation: [context: :IngestSheet, status: [:ok, :error]]
      ]
    ]
  end
end
