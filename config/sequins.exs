import Config

alias Meadow.Pipeline.Actions.{
  CopyFileToPreservation,
  CreatePyramidTiff,
  ExtractMimeType,
  FileSetComplete,
  GenerateFileSetDigests,
  ExtractExifMetadata,
  IngestFileSet
}

config :sequins,
  prefix: "meadow",
  supervisor_opts: [max_restarts: 2048]

config :sequins, Meadow.Pipeline,
  actions: [
    IngestFileSet,
    ExtractMimeType,
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    CreatePyramidTiff,
    FileSetComplete
  ]

config :sequins, IngestFileSet, queue_config: [processor_concurrency: 10]

config :sequins, ExtractMimeType,
  queue_config: [producer_concurrency: 10, processor_concurrency: 100, visibility_timeout: 120],
  notify_on: [IngestFileSet: [status: :ok], ExtractMimeType: [status: :retry]]

config :sequins, GenerateFileSetDigests,
  queue_config: [producer_concurrency: 10, processor_concurrency: 100, visibility_timeout: 600],
  notify_on: [ExtractMimeType: [status: :ok], GenerateFileSetDigests: [status: :retry]]

config :sequins, CopyFileToPreservation,
  queue_config: [producer_concurrency: 10, processor_concurrency: 100],
  notify_on: [GenerateFileSetDigests: [status: :ok], CopyFileToPreservation: [status: :retry]]

config :sequins, ExtractExifMetadata,
  queue_config: [producer_concurrency: 10, processor_concurrency: 100, visibility_timeout: 600],
  notify_on: [CopyFileToPreservation: [status: :ok], ExtractExifMetadata: [status: :retry]]

config :sequins, CreatePyramidTiff,
  queue_config: [producer_concurrency: 10, processor_concurrency: 100, visibility_timeout: 600],
  notify_on: [
    ExtractExifMetadata: [status: :ok, role: "am"],
    CreatePyramidTiff: [status: :retry]
  ]

config :sequins, FileSetComplete,
  queue_config: [processor_concurrency: 10],
  notify_on: [
    CreatePyramidTiff: [status: :ok],
    FileSetComplete: [status: :retry],
    ExtractExifMetadata: [status: :ok, role: "pm"]
  ]
