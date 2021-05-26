defmodule Meadow.Pipeline.Actions.TranscodeComplete do
  @moduledoc """
  Action to handle job state change messages from MediaConvert
  """

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Ingest.{Progress, Rows}

  use Sequins.Pipeline.Action
  use Meadow.Utils.Logging

  require Logger

  @impl true
  def process(%{detail_type: "MediaConvert Job State Change"} = message, _attributes) do
    with {data, attributes} <- parse(message) do
      process(data, attributes)
    end
  end

  def process(%{file_set_id: file_set_id} = data, attributes) do
    with_log_metadata module: __MODULE__, id: data.file_set_id do
      with {status, response} <-
             file_set_id |> FileSets.get_file_set() |> process_mediaconvert_response(data) do
        update_progress(attributes, status)
        {status, response, attributes}
      end
    end
  end

  defp parse(message) do
    {%{
       file_set_id: message |> get_in([:detail, :user_metadata, :file_set_id]),
       status: message |> get_in([:detail, :status]),
       error: message |> get_in([:detail, :error_message]),
       playlist: message |> extract_playlist()
     },
     message
     |> get_in([:detail, :user_metadata])
     |> Map.delete(:file_set_id)}
  end

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

  defp process_mediaconvert_response(file_set, %{status: "COMPLETE", playlist: playlist}) do
    derivatives = FileSets.add_derivative(file_set, :playlist, playlist)
    FileSets.update_file_set(file_set, %{derivatives: derivatives})
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    {:ok, %{file_set_id: file_set.id}}
  end

  defp process_mediaconvert_response(file_set, %{status: "ERROR", error: error}) do
    ActionStates.set_state!(file_set, __MODULE__, "error", error)
    {:error, error}
  end

  defp update_progress(%{ingest_sheet: sheet_id, ingest_sheet_row: row_num}, status) do
    Rows.get_row(sheet_id, row_num)
    |> Progress.update_entry(__MODULE__, to_string(status))
  end

  defp update_progress(_, _), do: :noop
end
