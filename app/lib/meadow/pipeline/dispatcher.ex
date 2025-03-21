defmodule Meadow.Pipeline.Dispatcher do
  @moduledoc """
  Action responsible for dispatching processing to
  the next action in the pipeline

  Subscribes to: all other actions with status: :ok
  *

  """
  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Meadow.Utils.Pairtree

  alias Meadow.Pipeline.Actions.{
    CopyFileToPreservation,
    CreateDerivativeCopy,
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

  alias Meadow.Data.FileSets

  require Logger

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

  @auxiliary_derivative_actions [
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    CreateDerivativeCopy,
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

  def initial_actions, do: @initial_actions

  def all_progress_actions, do: @all_actions

  def dispatcher_actions(_file_set, %{custom_actions: custom_actions}) do
    custom_actions
    |> String.split(~r/\s*\|\s*/)
    |> Enum.map(&Module.safe_concat(Meadow.Pipeline.Actions, &1))
  end

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "image/" <> _}},
        _attributes
      ),
      do: @access_image_actions

  def dispatcher_actions(
        %{role: %{id: "X"}, core_metadata: %{mime_type: "image/" <> _}},
        _attributes
      ),
      do: @access_image_actions

  def dispatcher_actions(
        %{role: %{id: "X"}, core_metadata: %{mime_type: "application/pdf"}},
        _attributes
      ),
      do: @auxiliary_derivative_actions

  def dispatcher_actions(
        %{role: %{id: "X"}, core_metadata: %{mime_type: "application/zip"}},
        _attributes
      ),
      do: @auxiliary_derivative_actions

  def dispatcher_actions(
        %{role: %{id: "X"}, core_metadata: %{mime_type: "application/zip" <> _}},
        _attributes
      ),
      do: @auxiliary_derivative_actions

  def dispatcher_actions(
        %{role: %{id: "P"}, core_metadata: %{mime_type: "image/" <> _}},
        _attributes
      ),
      do: @preservation_image_actions

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "audio/" <> _}},
        %{context: "Version"}
      ),
      do: @access_audio_actions

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "audio/" <> _}} = file_set,
        _attributes
      ) do
    case skip_transcode?(file_set) do
      true ->
        @skip_transcode_actions

      _ ->
        @access_audio_actions
    end
  end

  def dispatcher_actions(
        %{role: %{id: "P"}, core_metadata: %{mime_type: "audio/" <> _}},
        _attributes
      ),
      do: @preservation_audio_actions

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "video/" <> _}},
        %{context: "Version"}
      ),
      do: @access_video_actions

  def dispatcher_actions(
        %{role: %{id: "A"}, core_metadata: %{mime_type: "video/" <> _}} = file_set,
        _attributes
      ) do
    case skip_transcode?(file_set) do
      true ->
        @skip_transcode_actions

      _ ->
        @access_video_actions
    end
  end

  def dispatcher_actions(
        %{role: %{id: "P"}, core_metadata: %{mime_type: "video/" <> _}},
        _attributes
      ),
      do: @preservation_video_actions

  def dispatcher_actions(%{role: %{id: "P"}}, _attributes),
    do: @preservation_actions

  def dispatcher_actions(%{role: %{id: "S"}}, _attributes),
    do: @preservation_actions

  def dispatcher_actions(_, _), do: nil

  def not_my_actions(file_set, attributes) do
    (all_progress_actions() -- @initial_actions) -- dispatcher_actions(file_set, attributes)
  end

  defp skip_transcode?(file_set) do
    Config.streaming_bucket()
    |> ExAws.S3.list_objects_v2(prefix: Pairtree.generate!(file_set.id))
    |> ExAws.request!()
    |> get_in([:body, :key_count])
    |> String.to_integer()
    |> then(&(&1 > 0))
  end

  def process(%{file_set_id: file_set_id}, attributes \\ %{}) do
    FileSets.get_file_set(file_set_id)
    |> dispatch_next_action(attributes)
  end

  def dispatch_next_action(file_set, %{process: action, status: "ok"} = attributes),
    do: dispatch_next_action(file_set, action, attributes)

  def dispatch_next_action(file_set, %{process: action, status: "retry"} = attributes),
    do: action.send_message(%{file_set_id: file_set.id}, attributes)

  def dispatch_next_action(file_set, attributes) do
    with_log_metadata module: __MODULE__, attributes: attributes do
      Logger.warning("Unexpected dispatch state for #{file_set.id}, #{attributes}")
      :noop
    end
  end

  def dispatch_next_action(file_set, last_action, attributes) do
    last = Module.safe_concat(Meadow.Pipeline.Actions, last_action)

    case next_action(last, dispatcher_actions(file_set, attributes)) do
      nil ->
        :noop

      TranscodeComplete ->
        # Never dispatch directly to TranscodeComplete
        :noop

      next_action ->
        with_log_metadata module: __MODULE__, id: file_set.id do
          "Last action was: #{last}, next action is: #{next_action} for file set id: #{file_set.id}"
          |> Logger.info()
        end

        next_action.send_message(%{file_set_id: file_set.id}, attributes)
    end
  end

  def next_action(CreateTranscodeJob, _), do: nil

  def next_action(TranscodeComplete, _), do: FileSetComplete

  def next_action(last_action, dispatch_queue) do
    with action_queue <- @initial_actions ++ dispatch_queue do
      index = action_queue |> Enum.find_index(&(&1 == last_action))

      case index do
        nil ->
          Enum.at(action_queue, 0)

        number ->
          Enum.at(action_queue, number + 1)
      end
    end
  end
end
