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

config :sequins, IngestFileSet,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, processor_concurrency: 10]

config :sequins, ExtractMimeType,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [IngestFileSet: [status: :ok], ExtractMimeType: [status: :retry]]

config :sequins, GenerateFileSetDigests,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [ExtractMimeType: [status: :ok], GenerateFileSetDigests: [status: :retry]]

config :sequins, CopyFileToPreservation,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, visibility_timeout: 300],
  notify_on: [GenerateFileSetDigests: [status: :ok], CopyFileToPreservation: [status: :retry]]

config :sequins, ExtractExifMetadata,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [CopyFileToPreservation: [status: :ok], ExtractExifMetadata: [status: :retry]]

config :sequins, CreatePyramidTiff,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [
    ExtractExifMetadata: [status: :ok, role: "am"],
    CreatePyramidTiff: [status: :retry]
  ]

config :sequins, FileSetComplete,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, processor_concurrency: 10],
  notify_on: [
    CreatePyramidTiff: [status: :ok],
    FileSetComplete: [status: :retry],
    ExtractExifMetadata: [status: :ok, role: "pm"]
  ]
