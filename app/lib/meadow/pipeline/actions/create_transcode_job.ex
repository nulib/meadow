defmodule Meadow.Pipeline.Actions.CreateTranscodeJob do
  @moduledoc """
  Action to create an AWS Elemental MediaConvert Job for an audio or video file
  """

  alias Meadow.Data.{ActionStates, FileSets}
  alias MediaConvert.{AudioTemplate, VideoTemplate}

  use Meadow.Pipeline.Actions.Common

  require Logger

  def actiondoc, do: "Create an AWS Elemental MediaConvert Job for an audio or video FileSet"

  def already_complete?(file_set, _) do
    ActionStates.ok?(file_set.id, __MODULE__)
  end

  def process(file_set, attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    source = file_set.core_metadata.location
    destination = FileSets.streaming_uri_for(file_set)
    mime_type = file_set.core_metadata.mime_type
    user_metadata = Map.put(attributes, :file_set_id, file_set.id)

    case transcode(user_metadata, mime_type, source, destination) do
      {:ok, job_id} ->
        Logger.info("MediaConvert Job #{job_id} created")
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, error} ->
        ActionStates.set_state!(file_set, __MODULE__, "error", error)
        {:error, error}
    end
  end

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
