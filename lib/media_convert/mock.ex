defmodule MediaConvert.Mock do
  @moduledoc """
  Mock AWS Elemental MediaConvert client
  """
  alias Meadow.Pipeline.Actions.TranscodeComplete

  def configure! do
    :ok
  end

  @doc """
  Simulate responses from creating jobs via the MediaConvert HTTP API

  To return an error tuple, make sure the MediaConvert template passed in has a :FileInput value containing
  the word "error", e.g. %{FileInput: "s3://error/test.mov"} => {:error, "Fake error response"}
  """
  def create_job(template) do
    if String.match?(file_input(template), ~r/input-error/) do
      {:error, "Fake error response"}
    else
      send_transcode_complete(template)
      {:ok, "fake-job-id"}
    end
  end

  defp file_input(%{Settings: %{Inputs: [%{FileInput: file_input}]}}), do: file_input
  defp file_input(_template), do: ""

  defp destination(%{
         Settings: %{
           OutputGroups: [
             %{OutputGroupSettings: %{CmafGroupSettings: %{Destination: destination}}}
           ]
         }
       }),
       do: destination

  defp destination(_template), do: ""

  defp send_transcode_complete(template) do
    if String.match?(file_input(template), ~r/transcode-error/) do
      event(template, "ERROR")
    else
      event(template, "COMPLETE")
    end
    |> TranscodeComplete.send_message(%{})
  end

  defp event(template, "COMPLETE") do
    playlist_path =
      Path.join(destination(template), file_input(template) |> Path.basename()) <> ".m3u8"

    timestamp = DateTime.utc_now()
    metadata = template |> Map.get(:UserMetadata, %{})

    %{
      account: "012345678901",
      detail: %{
        accountId: "012345678901",
        jobId: "fake-job-id",
        outputGroupDetails: [
          %{
            outputDetails: [
              %{
                durationInMs: 5538,
                videoDetails: %{heightInPx: 720, widthInPx: 1280}
              },
              %{durationInMs: 5526}
            ],
            playlistFilePaths: [playlist_path],
            type: "CMAF_GROUP"
          }
        ],
        queue: template |> Map.get(:Queue),
        status: "COMPLETE",
        timestamp: DateTime.to_unix(timestamp, :millisecond),
        userMetadata: metadata
      },
      "detail-type": "MediaConvert Job State Change",
      id: Ecto.UUID.generate(),
      region: ExAws.Config.new(:mediaconvert) |> Map.get(:region),
      resources: ["arn:aws:mediaconvert:us-east-1:012345678901:jobs/fake-job-id"],
      source: "aws.mediaconvert",
      time: timestamp |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      version: "0"
    }
  end

  defp event(template, "ERROR") do
    timestamp = DateTime.utc_now()
    metadata = template |> Map.get(:UserMetadata, %{})

    %{
      account: "012345678901",
      detail: %{
        accountId: "012345678901",
        errorCode: 1401,
        errorMessage: "Unable to open input file [#{file_input(template)}]",
        jobId: "fake-job-id",
        queue: template |> Map.get(:Queue),
        status: "ERROR",
        timestamp: DateTime.to_unix(timestamp, :millisecond),
        userMetadata: metadata
      },
      "detail-type": "MediaConvert Job State Change",
      id: Ecto.UUID.generate(),
      region: ExAws.Config.new(:mediaconvert) |> Map.get(:region),
      resources: ["arn:aws:mediaconvert:us-east-1:012345678901:jobs/fake-job-id"],
      source: "aws.mediaconvert",
      time: timestamp |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      version: "0"
    }
  end
end
