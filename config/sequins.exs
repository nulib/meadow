import Config

alias Meadow.Pipeline.Actions.{
  CopyFileToPreservation,
  CreatePyramidTiff,
  CreateTranscodeJob,
  Dispatcher,
  ExtractMediaMetadata,
  ExtractMimeType,
  FileSetComplete,
  GenerateFileSetDigests,
  GeneratePosterImage,
  ExtractExifMetadata,
  IngestFileSet,
  InitializeDispatch,
  TranscodeComplete
}

config :sequins,
  prefix: "meadow",
  supervisor_opts: [max_restarts: 2048]

config :sequins, Meadow.Pipeline,
  actions: [
    IngestFileSet,
    ExtractMimeType,
    InitializeDispatch,
    Dispatcher,
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    CreatePyramidTiff,
    ExtractMediaMetadata,
    CreateTranscodeJob,
    TranscodeComplete,
    GeneratePosterImage,
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

config :sequins, InitializeDispatch,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, processor_concurrency: 10],
  notify_on: [
    ExtractMimeType: [status: :ok],
    InitializeDispatch: [status: :retry]
  ]

config :sequins, GenerateFileSetDigests,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [GenerateFileSetDigests: [status: :retry]]

config :sequins, CopyFileToPreservation,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, visibility_timeout: 300],
  notify_on: [CopyFileToPreservation: [status: :retry]]

config :sequins, ExtractExifMetadata,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [ExtractExifMetadata: [status: :retry]]

config :sequins, ExtractMediaMetadata,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 960
  ],
  notify_on: [ExtractMediaMetadata: [status: :retry]]

config :sequins, CreatePyramidTiff,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [
    CreatePyramidTiff: [status: :retry]
  ]

config :sequins, CreateTranscodeJob,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [
    CreateTranscodeJob: [status: :retry]
  ]

config :sequins, TranscodeComplete,
  queue_config: [
    receive_interval: 1000,
    wait_time_seconds: 1,
    processor_concurrency: 1,
    visibility_timeout: 300
  ],
  notify_on: [
    TranscodeComplete: [status: :retry]
  ]

config :sequins, GeneratePosterImage,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, visibility_timeout: 300],
  notify_on: [GeneratePosterImage: [status: :retry]]

config :sequins, FileSetComplete,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, processor_concurrency: 10],
  notify_on: [
    FileSetComplete: [status: :retry]
  ]

config :sequins, Dispatcher,
  queue_config: [receive_interval: 1000, wait_time_seconds: 1, processor_concurrency: 10],
  notify_on: [
    InitializeDispatch: [status: :ok],
    GenerateFileSetDigests: [status: :ok],
    CopyFileToPreservation: [status: :ok],
    ExtractExifMetadata: [status: :ok],
    ExtractMediaMetadata: [status: :ok],
    CreatePyramidTiff: [status: :ok],
    TranscodeComplete: [status: :ok]
  ]
