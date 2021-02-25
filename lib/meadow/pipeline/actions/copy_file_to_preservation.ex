defmodule Meadow.Pipeline.Actions.CopyFileToPreservation do
  @moduledoc """
  Action to copy the file referenced in a FileSet
  to the pre-configured preservation bucket.

  Subscribes to:
  *

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Pairtree
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common
  require Logger
  import SweetXml, only: [sigil_x: 2]

  @actiondoc "Copy File to Preservation"

  defp already_complete?(file_set, _) do
    with dest_location <- preservation_location(file_set) do
      if file_set.metadata.location == dest_location,
        do: Meadow.Utils.Stream.exists?(dest_location),
        else: false
    end
  end

  defp process(file_set, attributes, _) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    case copy_file_to_preservation(file_set, attributes) do
      {:ok, new_location} ->
        file_set
        |> FileSets.update_file_set(%{metadata: %{location: new_location}})

        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, err} ->
        ActionStates.set_state!(file_set, __MODULE__, "error", err)
        {:error, err}
    end
  end

  defp preservation_location(file_set) do
    dest_bucket = Config.preservation_bucket()

    dest_key =
      Path.join(["/", Pairtree.preservation_path(Map.get(file_set.metadata.digests, "sha256"))])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  defp copy_file_to_preservation(file_set, attributes) do
    with dest_location <- preservation_location(file_set),
         overwrite <- attributes |> Map.get(:overwrite, false) do
      if overwrite or Meadow.Utils.Stream.exists?(dest_location) do
        Logger.info("#{dest_location} already exists")
        {:ok, dest_location}
      else
        copy_file_if_missing(file_set, dest_location)
      end
    end
  rescue
    ArgumentError -> {:error, "Error creating preservation path"}
  end

  defp copy_file_if_missing(file_set, dest_location) do
    with src_location <- file_set.metadata.location,
         %{host: src_bucket, path: "/" <> src_key} <- URI.parse(src_location),
         %{host: dest_bucket, path: "/" <> dest_key} <- URI.parse(dest_location),
         original_filename <- file_set.metadata.original_filename,
         s3_metadata <- file_set.metadata.digests |> Enum.into([]) do
      Logger.info("Copying #{original_filename} from #{src_location} to #{dest_location}")

      content_type =
        case file_set.metadata.mime_type do
          nil -> "application/octet-stream"
          mime_type -> mime_type
        end

      case ExAws.S3.put_object_copy(
             dest_bucket,
             dest_key,
             src_bucket,
             src_key,
             content_type: content_type,
             metadata_directive: :REPLACE,
             meta: s3_metadata
           )
           |> ExAws.request() do
        {:ok, _} -> {:ok, dest_location}
        {:error, {:http_error, _status, %{body: body}}} -> {:error, extract_error(body)}
        {:error, other} -> {:error, inspect(other)}
      end
    end
  end

  defp extract_error(body) do
    with error <-
           SweetXml.xmap(body, code: ~x"/Error/Code/text()", message: ~x"/Error/Message/text()") do
      "#{error.code}: #{error.message}"
    end
  end
end
