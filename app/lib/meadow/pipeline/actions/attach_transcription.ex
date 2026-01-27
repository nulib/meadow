defmodule Meadow.Pipeline.Actions.AttachTranscription do
  @moduledoc """
  Action to create a transcription annotation for a FileSet
  if a transcription file is specified in the ingest sheet.

  Subscribes to:
  *

  """
  alias Meadow.Data.{ActionStates, FileSets}
  use Meadow.Pipeline.Actions.Common

  def actiondoc, do: "Attach Transcription"

  def already_complete?(file_set, _) do
    get_transcription_file(file_set)
    |> is_nil()
  end

  def process(file_set, _attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    case create_transcription_for_file_set(file_set, get_transcription_file(file_set)) do
      {:ok, _annotation} ->
        remove_transcription_file(file_set)
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, err} ->
        ActionStates.set_state!(file_set, __MODULE__, "error", err)
        {:error, err}
    end
  end

  defp create_transcription_for_file_set(_file_set, nil), do: {:ok, nil}

  defp create_transcription_for_file_set(file_set, file_location) do
    with %URI{host: bucket, path: "/" <> key} <- URI.parse(file_location),
         {:ok, annotation} <-
           FileSets.create_annotation(file_set, %{
             type: "transcription",
             status: "completed",
             language: ["en"]
           }) do
      case FileSets.copy_annotation_content(annotation, bucket, key) do
        {:ok, s3_location} ->
          FileSets.update_annotation(annotation, %{s3_location: s3_location})
        {:error, reason} ->
          Logger.error("Failed to copy transcription content: #{inspect(reason)}")
          FileSets.delete_annotation(annotation)
          {:error, reason}
        end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to create annotation: #{inspect(changeset.errors)}")
        {:error, inspect(changeset.errors)}

      {:error, reason} ->
        Logger.error("Failed to create annotation: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_transcription_file(file_set) do
    Map.get(file_set, :derivatives, %{})
    |> Map.get("transcription_file")
  end

  defp remove_transcription_file(file_set) do
    derivatives = Map.get(file_set, :derivatives, %{}) |> Map.delete("transcription_file")
    FileSets.update_file_set(file_set, %{derivatives: derivatives})
  end
end
