use Mix.Config

alias Meadow.Pipeline.Actions.{
  CopyFileToPreservation,
  CreatePyramidTiff,
  FileSetComplete,
  GenerateFileSetDigests,
  IngestFileSet,
  UpdateSheetStatus
}

config :sequins, prefix: "meadow"

config :sequins, Meadow.Pipeline,
  actions: [
    IngestFileSet,
    GenerateFileSetDigests,
    CopyFileToPreservation,
    CreatePyramidTiff,
    FileSetComplete,
    UpdateSheetStatus
  ]

config :sequins, IngestFileSet, queue_config: [processor_stages: 1]

config :sequins, GenerateFileSetDigests,
  queue_config: [max_number_of_messages: 3, visibility_timeout: 180],
  notify_on: [IngestFileSet: [status: :ok]]

config :sequins, CopyFileToPreservation,
  queue_config: [max_number_of_messages: 3, visibility_timeout: 180],
  notify_on: [GenerateFileSetDigests: [status: :ok]]

config :sequins, CreatePyramidTiff,
  queue_config: [processor_stages: 1],
  notify_on: [CopyFileToPreservation: [status: :ok]]

config :sequins, FileSetComplete,
  queue_config: [processor_stages: 1],
  notify_on: [CreatePyramidTiff: [status: :ok]]

config :sequins, UpdateSheetStatus,
  queue_config: [processor_stages: 1],
  ignore: true,
  notify_on: [
    IngestFileSet: [context: :Sheet, status: :error],
    GenerateFileSetDigests: [context: :Sheet, status: :error],
    CopyFileToPreservation: [context: :Sheet, status: :error],
    CreatePyramidTiff: [context: :Sheet, status: :error],
    FileSetComplete: [context: :Sheet, status: [:ok, :error]]
  ]
