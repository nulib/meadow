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

  defp process(data, _attributes, _) do
    file_set = FileSets.get_file_set!(data.file_set_id)
    ActionStates.set_state!(file_set, __MODULE__, "started")

    case copy_file_to_preservation(file_set) do
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

  defp copy_file_to_preservation(file_set) do
    src_location = file_set.metadata.location
    %{host: src_bucket, path: "/" <> src_key} = URI.parse(src_location)

    dest_bucket = Config.preservation_bucket()

    try do
      dest_key =
        Path.join(["/", Pairtree.preservation_path(Map.get(file_set.metadata.digests, "sha256"))])

      original_filename = file_set.metadata.original_filename
      dest_location = %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()

      s3_metadata = [
        sha1: file_set.metadata.digests["sha1"],
        sha256: file_set.metadata.digests["sha256"]
      ]

      Logger.info("Copying #{original_filename} from #{src_location} to #{dest_location}")

      case ExAws.S3.put_object_copy(
             dest_bucket,
             dest_key,
             src_bucket,
             src_key,
             metadata_directive: :REPLACE,
             meta: s3_metadata
           )
           |> ExAws.request() do
        {:ok, _} -> {:ok, dest_location}
        {:error, {:http_error, _status, %{body: body}}} -> {:error, extract_error(body)}
        {:error, other} -> {:error, inspect(other)}
      end
    rescue
      ArgumentError -> {:error, "Error creating preservation path"}
    end
  end

  defp extract_error(body) do
    with error <-
           SweetXml.xmap(body, code: ~x"/Error/Code/text()", message: ~x"/Error/Message/text()") do
      "#{error.code}: #{error.message}"
    end
  end
end
