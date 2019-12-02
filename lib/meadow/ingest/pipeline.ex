defmodule Meadow.Ingest.Pipeline do
  @moduledoc """
  Defines the supervision tree for the ingest pipeline
  """
  alias Meadow.Ingest.Actions

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def actions do
    [
      Actions.IngestFileSet,
      Actions.GenerateFileSetDigests,
      Actions.CopyFileToPreservation,
      Actions.FileSetComplete
    ]
  end

  def children do
    [
      {Actions.CopyFileToPreservation, max_number_of_messages: 3, visibility_timeout: 180},
      {Actions.GenerateFileSetDigests, max_number_of_messages: 3, visibility_timeout: 180},
      {Actions.IngestFileSet, processor_stages: 1},
      {Actions.UpdateIngestSheetStatus, processor_stages: 1},
      {Actions.FileSetComplete, processor_stages: 1}
    ]
  end

  def start do
    Application.ensure_started(:sequins, :permanent)
    Sequins.start_children(children())
  end

  def queue_config do
    [
      IngestFileSet: [],
      GenerateFileSetDigests: [IngestFileSet: [status: :ok]],
      CopyFileToPreservation: [GenerateFileSetDigests: [status: :ok]],
      FileSetComplete: [CopyFileToPreservation: [status: :ok]],
      UpdateIngestSheetStatus: [
        IngestFileSet: [context: :IngestSheet, status: :error],
        GenerateFileSetDigests: [context: :IngestSheet, status: :error],
        CopyFileToPreservation: [context: :IngestSheet, status: :error],
        FileSetComplete: [context: :IngestSheet, status: [:ok, :error]]
      ]
    ]
  end
end
