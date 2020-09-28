use Mix.Config

alias Meadow.Pipeline.Actions.{
  CopyFileToPreservation,
  CreatePyramidTiff,
  FileSetComplete,
  GenerateFileSetDigests,
  IngestFileSet
}

config :sequins,
  prefix: "meadow",
  supervisor_opts: [max_restarts: 2048]

config :sequins, Meadow.Pipeline,
  actions: [
    IngestFileSet,
    GenerateFileSetDigests,
    CopyFileToPreservation,
    CreatePyramidTiff,
    FileSetComplete
  ]

config :sequins, IngestFileSet, queue_config: [processor_concurrency: 1]

config :sequins, GenerateFileSetDigests,
  queue_config: [max_number_of_messages: 3, visibility_timeout: 180],
  notify_on: [IngestFileSet: [status: :ok], GenerateFileSetDigests: [status: :retry]]

config :sequins, CopyFileToPreservation,
  queue_config: [max_number_of_messages: 3, visibility_timeout: 180],
  notify_on: [GenerateFileSetDigests: [status: :ok], CopyFileToPreservation: [status: :retry]]

config :sequins, CreatePyramidTiff,
  queue_config: [processor_concurrency: 1],
  notify_on: [CopyFileToPreservation: [status: :ok], CreatePyramidTiff: [status: :retry]]

config :sequins, FileSetComplete,
  queue_config: [processor_concurrency: 1],
  notify_on: [CreatePyramidTiff: [status: :ok], FileSetComplete: [status: :retry]]
