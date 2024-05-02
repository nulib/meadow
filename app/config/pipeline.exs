import Config
import Env

prefix =
  case System.get_env("DEV_PREFIX") do
    nil -> "meadow"
    _ -> prefix()
  end

alias Meadow.Pipeline.Actions.{
  CopyFileToPreservation,
  CreateDerivativeCopy,
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

config :meadow, Meadow.Pipeline, [
  {:actions,
   [
     IngestFileSet,
     ExtractMimeType,
     InitializeDispatch,
     GenerateFileSetDigests,
     ExtractExifMetadata,
     CopyFileToPreservation,
     CreateDerivativeCopy,
     CreatePyramidTiff,
     ExtractMediaMetadata,
     CreateTranscodeJob,
     TranscodeComplete,
     GeneratePosterImage,
     FileSetComplete
   ]},
  {IngestFileSet,
   producer: [
     queue_name: "#{prefix}-ingest-file-set",
     wait_time_seconds: 1
   ],
   processors: [default: [concurrency: 10]]},
  {ExtractMimeType,
   producer: [
     queue_name: "#{prefix}-extract-mime-type",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {InitializeDispatch,
   producer: [
     queue_name: "#{prefix}-initialize-dispatch",
     wait_time_seconds: 1
   ]},
  {GenerateFileSetDigests,
   producer: [
     queue_name: "#{prefix}-generate-file-set-digests",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {CopyFileToPreservation,
   producer: [
     queue_name: "#{prefix}-copy-file-to-preservation",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ]},
  {ExtractExifMetadata,
   producer: [
     queue_name: "#{prefix}-extract-exif-metadata",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {ExtractMediaMetadata,
   producer: [
     queue_name: "#{prefix}-extract-media-metadata",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {CreatePyramidTiff,
   producer: [
     queue_name: "#{prefix}-create-pyramid-tiff",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
   {CreateDerivativeCopy,
   producer: [
     queue_name: "#{prefix}-create-derivative-copy",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {CreateTranscodeJob,
   producer: [
     queue_name: "#{prefix}-create-transcode-job",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {TranscodeComplete,
   producer: [
     queue_name: "#{prefix}-transcode-complete",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ],
   processors: [default: [concurrency: 1]]},
  {GeneratePosterImage,
   producer: [
     queue_name: "#{prefix}-generate-poster-image",
     wait_time_seconds: 1,
     visibility_timeout: 300
   ]},
  {FileSetComplete,
   producer: [
     queue_name: "#{prefix}-file-set-complete",
     wait_time_seconds: 1
   ]}
]
