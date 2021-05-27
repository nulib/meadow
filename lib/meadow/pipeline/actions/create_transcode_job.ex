defmodule Meadow.Pipeline.Actions.CreateTranscodeJob do
  @moduledoc """
  Action to create an AWS Elemental MediaConvert Job for an audio or video file
  """

  alias Meadow.Data.{ActionStates, FileSets}
  alias MediaConvert.{AudioTemplate, VideoTemplate}
  alias Sequins.Pipeline.Action

  use Action
  use Meadow.Pipeline.Actions.Common

  require Logger

  @actiondoc "Create an AWS Elemental MediaConvert Job for an audio or video FileSet"

  defp already_complete?(file_set, _) do
    ActionStates.ok?(file_set.id, __MODULE__)
  end

  defp process(file_set, attributes, _false) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    source = file_set.core_metadata.location
    destination = FileSets.streaming_uri_for(file_set)
    mime_type = file_set.core_metadata.mime_type
    user_metadata = Map.put(attributes, :file_set_id, file_set.id)

    if supported_mime_type?(mime_type) && file_set.role do
      case transcode(user_metadata, mime_type, source, destination) do
        {:ok, job_id} ->
          Logger.info("MediaConvert Job #{job_id} created")
          ActionStates.set_state!(file_set, __MODULE__, "ok")
          :ok

        {:error, error} ->
          ActionStates.set_state!(file_set, __MODULE__, "error", error)
          {:error, error}
      end
    else
      ActionStates.set_state!(file_set, __MODULE__, "n/a")
      :skip
    end
  end

  defp supported_mime_type?(nil), do: false
  defp supported_mime_type?(mime_type), do: String.match?(mime_type, ~r/^(audio|video)\/.+$/)

  defp transcode(user_metadata, "video/" <> _subtype, "s3://" <> _ = source, destination) do
    user_metadata
    |> VideoTemplate.render(source, destination)
    |> mediaconvert_client().create_job()
    |> handle_job()
  end

  defp transcode(user_metadata, "audio/" <> _subtype, "s3://" <> _ = source, destination) do
    user_metadata
    |> AudioTemplate.render(source, destination)
    |> mediaconvert_client().create_job()
    |> handle_job()
  end

  defp transcode(_file_set_id, _mime_type, source, _destination) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end

  defp handle_job({:ok, job_id}), do: {:ok, job_id}

  defp handle_job({:error, error}) do
    Logger.error("Error creating MediaConvert Job")
    {:error, error}
  end

  defp mediaconvert_client, do: Application.get_env(:meadow, :mediaconvert_client)
end
