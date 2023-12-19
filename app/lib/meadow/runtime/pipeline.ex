defmodule Meadow.Runtime.Pipeline do
  @moduledoc false

  import Config
  import Meadow.Runtime

  @actions [
    Actions.IngestFileSet,
    Actions.ExtractMimeType,
    Actions.InitializeDispatch,
    Actions.Dispatcher,
    Actions.GenerateFileSetDigests,
    Actions.ExtractExifMetadata,
    Actions.CopyFileToPreservation,
    Actions.CreatePyramidTiff,
    Actions.ExtractMediaMetadata,
    Actions.CreateTranscodeJob,
    Actions.TranscodeComplete,
    Actions.GeneratePosterImage,
    Actions.FileSetComplete
  ]

  def configure! do
    prefix = prefix() || "meadow"

    config :meadow, Meadow.Pipeline, [
      {:actions,
       [
         Actions.IngestFileSet,
         Actions.ExtractMimeType,
         Actions.InitializeDispatch,
         Actions.GenerateFileSetDigests,
         Actions.ExtractExifMetadata,
         Actions.CopyFileToPreservation,
         Actions.CreatePyramidTiff,
         Actions.ExtractMediaMetadata,
         Actions.CreateTranscodeJob,
         Actions.TranscodeComplete,
         Actions.GeneratePosterImage,
         Actions.FileSetComplete
       ]},
      {Actions.IngestFileSet,
       producer: [
         queue_name: "#{prefix}-ingest-file-set",
         wait_time_seconds: 1
       ],
       processors: [default: [concurrency: 10]]},
      {Actions.ExtractMimeType,
       producer: [
         queue_name: "#{prefix}-extract-mime-type",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.InitializeDispatch,
       producer: [
         queue_name: "#{prefix}-initialize-dispatch",
         wait_time_seconds: 1
       ]},
      {Actions.GenerateFileSetDigests,
       producer: [
         queue_name: "#{prefix}-generate-file-set-digests",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.CopyFileToPreservation,
       producer: [
         queue_name: "#{prefix}-copy-file-to-preservation",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ]},
      {Actions.ExtractExifMetadata,
       producer: [
         queue_name: "#{prefix}-extract-exif-metadata",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.ExtractMediaMetadata,
       producer: [
         queue_name: "#{prefix}-extract-media-metadata",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.CreatePyramidTiff,
       producer: [
         queue_name: "#{prefix}-create-pyramid-tiff",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.CreateTranscodeJob,
       producer: [
         queue_name: "#{prefix}-create-transcode-job",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.TranscodeComplete,
       producer: [
         queue_name: "#{prefix}-transcode-complete",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ],
       processors: [default: [concurrency: 1]]},
      {Actions.GeneratePosterImage,
       producer: [
         queue_name: "#{prefix}-generate-poster-image",
         wait_time_seconds: 1,
         visibility_timeout: 300
       ]},
      {Actions.FileSetComplete,
       producer: [
         queue_name: "#{prefix}-file-set-complete",
         wait_time_seconds: 1
       ]}
    ]

    Enum.each(@actions, &configure_action/1)
  end

  def actions, do: @actions

  defp configure_action(action) do
    key = action |> Module.split() |> List.last() |> Inflex.underscore() |> String.upcase()

    with receive_interval <- 1000,
         wait_time_seconds <- 1,
         max_number_of_messages <- 10 do
      config :meadow,
             Meadow.Pipeline,
             [
               {action,
                producer: [
                  receive_interval: receive_interval,
                  wait_time_seconds: wait_time_seconds,
                  max_number_of_messages: max_number_of_messages,
                  visibility_timeout:
                    environment("#{key}_VISIBILITY_TIMEOUT", cast: :integer, default: 300)
                ],
                processors: [
                  default: [
                    concurrency:
                      environment("#{key}_PROCESSOR_CONCURRENCY", cast: :integer, default: 10),
                    max_demand: environment("#{key}_MAX_DEMAND", cast: :integer, default: 10),
                    min_demand: environment("#{key}_MIN_DEMAND", cast: :integer, default: 5)
                  ]
                ]}
             ]
    end
  end
end
