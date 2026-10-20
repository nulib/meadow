defmodule Meadow.Pipeline.Actions.TranscodeComplete do
  @moduledoc """
  Action to handle job state change messages from MediaConvert
  """

  alias Broadway.Message
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Action
  alias Meadow.Pipeline.Actions.CreateTranscodeJob
  alias Meadow.Telemetry.Handlers
  alias Meadow.Utils.AWS

  use Meadow.Pipeline.Actions.Common
  use Meadow.Utils.Logging

  require Logger

  @event_type "MediaConvert Job State Change"

  # Upper bound on a believable transcode. Anything longer is treated as an unpaired
  # measurement rather than a very slow job.
  @max_duration :timer.hours(24)

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
      emit_transcode_duration(file_set, attributes, result)

      case result do
        {status, _} -> Action.update_progress(__MODULE__, status, file_set, attributes)
        status -> Action.update_progress(__MODULE__, status, file_set, attributes)
      end

      result
    end
  end

  def already_complete?(_, _), do: false

  # The transcode itself is bookended by two actions rather than contained in one, so its
  # duration can't come from a span. `CreateTranscodeJob` sends the start time out with the
  # job and MediaConvert hands it back here, which keeps the pairing exact across restarts,
  # redeploys and node changes without Meadow holding any state in between.
  defp emit_transcode_duration(file_set, attributes, result) do
    case transcode_duration(file_set, attributes) do
      nil ->
        :ok

      duration_ms ->
        :telemetry.execute(
          [:meadow, :pipeline, :transcode, :complete],
          %{duration_ms: duration_ms},
          %{
            file_set_id: file_set.id,
            media_type: Handlers.media_type(file_set.core_metadata.mime_type),
            outcome: transcode_outcome(result)
          }
        )
    end
  rescue
    exception ->
      Logger.warning("Unable to measure transcode duration: #{Exception.message(exception)}")
      :ok
  end

  defp transcode_outcome({:error, _}), do: "error"
  defp transcode_outcome(status) when is_atom(status), do: to_string(status)
  defp transcode_outcome(_), do: "unknown"

  defp transcode_duration(file_set, attributes) do
    case started_at(file_set, attributes) do
      nil -> nil
      started_at -> validate_duration(System.os_time(:millisecond) - started_at)
    end
  end

  # Jobs submitted before this instrumentation shipped carry no start time, so fall back to
  # when `CreateTranscodeJob` recorded success. That row is upserted, so a forced re-run
  # rewrites it and a skipped-as-complete action leaves it stale -- good enough as a
  # fallback, which is why it is only consulted when the metadata is absent.
  defp started_at(file_set, %{transcode_started_at: timestamp}) when is_binary(timestamp) do
    case Integer.parse(timestamp) do
      {milliseconds, ""} -> milliseconds
      _ -> started_at(file_set, %{})
    end
  end

  defp started_at(file_set, _attributes) do
    case ActionStates.get_latest_state(file_set.id, CreateTranscodeJob) do
      %{updated_at: updated_at} -> DateTime.to_unix(updated_at, :millisecond)
      _ -> nil
    end
  end

  # A negative or absurd duration means the two ends did not actually pair up -- a stale
  # fallback row, or clock skew between nodes. Publishing nothing beats publishing a
  # number that will be read as real.
  defp validate_duration(duration) when duration >= 0 and duration <= @max_duration,
    do: duration

  defp validate_duration(_), do: nil

  defp extract_playlist(message) do
    case message |> get_in([:detail, :output_group_details]) do
      [detail | _] ->
        detail |> get_in([:playlist_file_paths, Access.at(-1)])

      _ ->
        nil
    end
  end

  defp process_mediaconvert_response(
         file_set,
         %{
           detail: %{status: "COMPLETE", playlist: playlist}
         } = attributes
       ) do
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
