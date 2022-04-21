defmodule Meadow.Pipeline.Actions.Dispatcher do
  @moduledoc """
  Action responsible for dispatching processing to
  the next action in the pipeline

  Subscribes to: all other actions with status: :ok
  *

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Pairtree
  alias Sequins.Pipeline.Action

  alias Meadow.Pipeline.Actions.{
    CopyFileToPreservation,
    CreatePyramidTiff,
    CreateTranscodeJob,
    ExtractExifMetadata,
    ExtractMediaMetadata,
    ExtractMimeType,
    FileSetComplete,
    GenerateFileSetDigests,
    IngestFileSet,
    InitializeDispatch,
    TranscodeComplete
  }

  use Action
  require Logger

  @actiondoc "Disatch pipeline actions specific to role + mime_type"

  @initial_actions [
    IngestFileSet,
    ExtractMimeType,
    InitializeDispatch
  ]

  @access_image_actions [
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    CreatePyramidTiff,
    FileSetComplete
  ]

  @access_audio_actions [
    GenerateFileSetDigests,
    CopyFileToPreservation,
    ExtractMediaMetadata,
    CreateTranscodeJob,
    TranscodeComplete,
    FileSetComplete
  ]

  @access_video_actions @access_audio_actions

  @skip_transcode_actions [
    GenerateFileSetDigests,
    CopyFileToPreservation,
    ExtractMediaMetadata,
    FileSetComplete
  ]

  @preservation_actions [
    GenerateFileSetDigests,
    CopyFileToPreservation,
    FileSetComplete
  ]

  @preservation_audio_actions [
    GenerateFileSetDigests,
    CopyFileToPreservation,
    ExtractMediaMetadata,
    FileSetComplete
  ]

  @preservation_video_actions @preservation_audio_actions

  @preservation_image_actions [
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    FileSetComplete
  ]

  @all_actions [
                 @initial_actions,
                 @preservation_actions,
                 @preservation_image_actions,
                 @access_image_actions,
                 @preservation_audio_actions,
                 @preservation_video_actions,
                 @access_audio_actions,
                 @access_video_actions,
                 @skip_transcode_actions
               ]
               |> List.flatten()
               |> Enum.uniq()

  def process(data, attributes) do
    Logger.info("Dispatching #{data.file_set_id}")
    file_set = FileSets.get_file_set(data.file_set_id)

    dispatch_next_action(file_set, attributes)
    :ok
  end

  def process(data, attributes, _), do: process(data, attributes)

  def initial_actions, do: @initial_actions

  def all_progress_actions, do: @all_actions

  def dispatcher_actions(%{role: %{id: "A"}, core_metadata: %{mime_type: "image/" <> _}}),
    do: @access_image_actions

  def dispatcher_actions(%{role: %{id: "X"}, core_metadata: %{mime_type: "image/" <> _}}),
    do: @access_image_actions

  def dispatcher_actions(%{role: %{id: "P"}, core_metadata: %{mime_type: "image/" <> _}}),
    do: @preservation_image_actions

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "audio/" <> _}} = file_set
      ) do
    case skip_transcode?(file_set) do
      true ->
        @skip_transcode_actions

      _ ->
        @access_audio_actions
    end
  end

  def dispatcher_actions(%{role: %{id: "P"}, core_metadata: %{mime_type: "audio/" <> _}}),
    do: @preservation_audio_actions

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "video/" <> _}} = file_set
      ) do
    case skip_transcode?(file_set) do
      true ->
        @skip_transcode_actions

      _ ->
        @access_video_actions
    end
  end

  def dispatcher_actions(%{role: %{id: "P"}, core_metadata: %{mime_type: "video/" <> _}}),
    do: @preservation_video_actions

  def dispatcher_actions(%{role: %{id: "S"}}),
    do: @preservation_actions

  def dispatcher_actions(_), do: nil

  def not_my_actions(file_set) do
    (all_progress_actions() -- @initial_actions) -- dispatcher_actions(file_set)
  end

  defp skip_transcode?(file_set) do
    Config.streaming_bucket()
    |> ExAws.S3.list_objects_v2(prefix: Pairtree.generate!(file_set.id))
    |> ExAws.request!()
    |> get_in([:body, :key_count])
    |> String.to_integer()
    |> then(&(&1 > 0))
  end

  defp dispatch_next_action(file_set, %{process: action, status: "ok"} = attributes),
    do: dispatch_next_action(file_set, action, attributes)

  defp dispatch_next_action(file_set, %{process: "Dispatcher", status: "retry"} = attributes),
    do: dispatch_next_action(file_set, ActionStates.get_latest_state(file_set.id), attributes)

  defp dispatch_next_action(file_set, attributes) do
    Logger.warn("Unexpected dispatch state for #{file_set.id}, #{attributes}")
    :noop
  end

  defp dispatch_next_action(file_set, last_action, attributes) do
    last = Module.safe_concat(Meadow.Pipeline.Actions, last_action)

    next_action =
      next_action(
        last,
        dispatcher_actions(file_set)
      )

    Logger.info(
      "Last action was: #{last}, next action is: #{next_action} for file set id: #{file_set.id}"
    )

    next_action.send_message(%{file_set_id: file_set.id}, attributes)
  end

  defp next_action(TranscodeComplete, _), do: FileSetComplete

  defp next_action(last_action, action_queue) do
    index = action_queue |> Enum.find_index(&(&1 == last_action))

    case index do
      nil ->
        Enum.at(action_queue, 0)

      number ->
        Enum.at(action_queue, number + 1)
    end
  end
end
