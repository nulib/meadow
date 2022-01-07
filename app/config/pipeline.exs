import Config

prefix =
  case System.get_env("DEV_PREFIX") do
    nil -> "meadow"
    dev_prefix -> [dev_prefix, Mix.env()] |> Enum.reject(&is_nil/1) |> Enum.join("-")
  end

alias Meadow.Pipeline.Actions.{
  CopyFileToPreservation,
  CreatePyramidTiff,
  CreateTranscodeJob,
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

config :meadow, Meadow.Pipeline,
  actions: [
    IngestFileSet,
    ExtractMimeType,
    InitializeDispatch,
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

config :meadow, IngestFileSet,
  producer: [
    queue_name: "#{prefix}-ingest-file-set",
    wait_time_seconds: 1
  ],
  processors: [default: [concurrency: 10]]

config :meadow, ExtractMimeType,
  producer: [
    queue_name: "#{prefix}-extract-mime-type",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, InitializeDispatch,
  producer: [
    queue_name: "#{prefix}-initialize-dispatch",
    wait_time_seconds: 1
  ]

config :meadow, GenerateFileSetDigests,
  producer: [
    queue_name: "#{prefix}-generate-file-set-digests",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, CopyFileToPreservation,
  producer: [
    queue_name: "#{prefix}-copy-file-to-preservation",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ]

config :meadow, ExtractExifMetadata,
  producer: [
    queue_name: "#{prefix}-extract-exif-metadata",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, ExtractMediaMetadata,
  producer: [
    queue_name: "#{prefix}-extract-media-metadata",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, CreatePyramidTiff,
  producer: [
    queue_name: "#{prefix}-create-pyramid-tiff",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, CreateTranscodeJob,
  producer: [
    queue_name: "#{prefix}-create-transcode-job",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, TranscodeComplete,
  producer: [
    queue_name: "#{prefix}-transcode-complete",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ],
  processors: [default: [concurrency: 1]]

config :meadow, GeneratePosterImage,
  producer: [
    queue_name: "#{prefix}-generate-poster-image",
    wait_time_seconds: 1,
    visibility_timeout: 300
  ]

config :meadow, FileSetComplete,
  producer: [
    queue_name: "#{prefix}-file-set-complete",
    wait_time_seconds: 1
  ]
