defmodule Meadow.Pipeline.Actions.TranscodeComplete do
  @moduledoc """
  Action to handle job state change messages from MediaConvert
  """

  alias Broadway.Message
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Action
  alias Meadow.Utils.AWS

  use Meadow.Pipeline.Actions.Common
  use Meadow.Utils.Logging

  require Logger

  @event_type "MediaConvert Job State Change"

  def actiondoc, do: "Process completed media transcode"

  def prepare_file_set_id(%Message{data: {%{detail_type: @event_type}, _}} = message) do
    Message.update_data(message, fn {event, _} ->
      with file_set_id <- event |> get_in([:detail, :user_metadata, :file_set_id]) do
        {%{file_set_id: file_set_id},
         event
         |> get_in([:detail, :user_metadata])
         |> Map.delete(:file_set_id)
         |> Map.merge(%{
           file_set_id: file_set_id,
           detail: %{
             status: event |> get_in([:detail, :status]),
             error: event |> get_in([:detail, :error_message]),
             playlist: event |> extract_playlist()
           }
         })}
      end
    end)
  end

  def process(%FileSet{} = file_set, attributes) do
    with result <- file_set |> process_mediaconvert_response(attributes) do
      case result do
        {status, _} -> Action.update_progress(__MODULE__, status, file_set, attributes)
        status -> Action.update_progress(__MODULE__, status, file_set, attributes)
      end

      result
    end
  end

  def already_complete?(_, _), do: false

  defp extract_playlist(message) do
    case message |> get_in([:detail, :output_group_details]) do
      [detail | _] ->
        detail |> get_in([:playlist_file_paths, Access.at(-1)])

      _ ->
        nil
    end
  end

  defp process_mediaconvert_response(nil, %{file_set_id: file_set_id}) do
    Logger.warn(
      "Marking #{__MODULE__} for #{file_set_id} as error because the file set was not found"
    )

    {:error, "FileSet #{file_set_id} not found"}
  end

  defp process_mediaconvert_response(file_set, %{
         detail: %{status: "COMPLETE", playlist: playlist}
       } = attributes) do
    derivatives = FileSets.add_derivative(file_set, :playlist, playlist)
    FileSets.update_file_set(file_set, %{derivatives: derivatives})
    with %{context: "Version"} <- attributes do
      AWS.invalidate_cache(file_set, :streaming)
    end
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  defp process_mediaconvert_response(file_set, %{detail: %{status: "ERROR", error: error}}) do
    ActionStates.set_state!(file_set, __MODULE__, "error", error)
    {:error, error}
  end
end
