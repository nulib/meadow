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

  def start_link(opts) do
    children =
      case opts[:start] do
        true ->
          [
            Actions.CopyFileToPreservation,
            Actions.GenerateFileSetDigests,
            Actions.IngestFileSet,
            Actions.UpdateIngestSheetStatus
          ]

        false ->
          []
      end

    Supervisor.start_link(children, name: __MODULE__.Supervisor, strategy: :one_for_one)
  end

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
