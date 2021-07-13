defmodule MediaConvert.Mock do
  @moduledoc """
  Mock AWS Elemental MediaConvert client
  """
  alias ExAws.S3
  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Pipeline.Actions.TranscodeComplete

  require Logger

  def configure! do
    with bucket <- Config.streaming_bucket() do
      S3.put_bucket_policy(
        bucket,
        %{
          "Statement" => [
            %{
              "Action" => ["s3:GetBucketLocation", "s3:ListBucket"],
              "Effect" => "Allow",
              "Principal" => %{"AWS" => ["*"]},
              "Resource" => ["arn:aws:s3:::#{bucket}"]
            },
            %{
              "Action" => ["s3:GetObject"],
              "Effect" => "Allow",
              "Principal" => %{"AWS" => ["*"]},
              "Resource" => ["arn:aws:s3:::#{bucket}/*"]
            }
          ],
          "Version" => "2012-10-17"
        }
        |> Jason.encode!()
      )
      |> ExAws.request!()
    end

    :ok
  end

  @doc """
  Simulate responses from creating jobs via the MediaConvert HTTP API

  To return an error tuple, make sure the MediaConvert template passed in has a :FileInput value containing
  the word "error", e.g. %{FileInput: "s3://error/test.mov"} => {:error, "Fake error response"}
  """
  def create_job(template) do
    configure!()

    if String.match?(file_input(template), ~r/input-error/) do
      {:error, "Fake error response"}
    else
      send_transcode_complete(template)
      {:ok, "fake-job-id"}
    end
  end

  defp file_set(%{UserMetadata: %{file_set_id: file_set_id}}),
    do: FileSets.get_file_set!(file_set_id)

  defp file_input(%{Settings: %{Inputs: [%{FileInput: file_input}]}}), do: file_input
  defp file_input(_template), do: ""

  def file_output(template) do
    file_set = file_set(template)
    input = file_input(template)

    Path.join(
      destination(template),
      Path.basename(input, Path.extname(input)) <>
        Path.extname(file_set.core_metadata.original_filename)
    )
  end

  defp destination(%{
         Settings: %{
           OutputGroups: [
             %{OutputGroupSettings: %{HlsGroupSettings: %{Destination: destination}}}
           ]
         }
       }),
       do: destination

  defp destination(_template), do: ""

  defp media_type(%{Settings: %{Inputs: [%{AudioSelectorGroups: %{}}]}}), do: :audio
  defp media_type(%{Settings: %{Inputs: [%{VideoSelector: %{}}]}}), do: :video
  defp media_type(_), do: :unknown

  defp send_transcode_complete(template) do
    if String.match?(file_input(template), ~r/transcode-error/) do
      event(template, "ERROR")
    else
      template
      |> upload_transcode_artifacts()
      |> event("COMPLETE")
    end
    |> TranscodeComplete.send_message(%{})
  end

  defp upload_transcode_artifacts(template) do
    destination = file_output(template)

    Logger.debug("Uploading #{destination}")

    with %{host: source_bucket, path: "/" <> source_key} <- file_input(template) |> URI.parse(),
         %{host: destination_bucket, path: "/" <> destination_key} <- URI.parse(destination) do
      S3.put_object_copy(
        destination_bucket,
        destination_key,
        source_bucket,
        source_key,
        acl: :public_read
      )
      |> ExAws.request!()
    end

    template
  end

  defp event(template, "COMPLETE") do
    timestamp = DateTime.utc_now()
    metadata = template |> Map.get(:UserMetadata, %{})

    %{
      account: "012345678901",
      detail: %{
        accountId: "012345678901",
        jobId: "fake-job-id",
        outputGroupDetails: [output_details(template, media_type(template))],
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

  defp output_details(template, :video) do
    %{
      outputDetails: [
        %{
          durationInMs: 662_130,
          videoDetails: %{heightInPx: 360, widthInPx: 640}
        },
        %{durationInMs: 662_130}
      ],
      playlistFilePaths: [file_output(template)],
      type: "CMAF_GROUP"
    }
  end

  defp output_details(template, :audio) do
    %{
      outputDetails: [
        %{durationInMs: 199_459}
      ],
      playlistFilePaths: [file_output(template)],
      type: "FILE_GROUP"
    }
  end
end
