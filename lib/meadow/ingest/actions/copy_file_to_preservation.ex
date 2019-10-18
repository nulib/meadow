defmodule Meadow.Ingest.Actions.CopyFileToPreservation do
  @moduledoc """
  Action to copy the file referenced in a FileSet
  to the pre-configured preservation bucket.

  Subscribes to:
  *

  """
  alias Meadow.Config
  alias Meadow.Data.{AuditEntries, FileSets}
  alias Meadow.Data.FileSets.FileSet
  alias Meadow.Repo
  alias Meadow.Utils.Pairtree
  alias Sequins.Pipeline.Action
  use Action
  require Logger

  def process(data, attrs),
    do: process(data, attrs, AuditEntries.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(data, attributes, _) do
    AuditEntries.add_entry!(data.file_set_id, __MODULE__, "started")
    file_set = FileSets.get_file_set!(data.file_set_id)

    case copy_file_to_preservation(file_set) do
      {:ok, new_location} ->
        file_set
        |> FileSet.changeset(%{metadata: %{location: new_location}})
        |> Repo.update!()

        AuditEntries.add_entry!(file_set.id, __MODULE__, "ok")
        :ok

      {:error, err} ->
        AuditEntries.add_entry!(file_set.id, __MODULE__, "error", err)
        {:error, data, attributes |> Map.put(:error, err)}
    end
  end

  defp copy_file_to_preservation(file_set) do
    src_location = file_set.metadata.location
    %{host: src_bucket, path: "/" <> src_key} = URI.parse(src_location)

    dest_bucket = Config.preservation_bucket()

    dest_key =
      Path.join([
        "/",
        Pairtree.generate!(file_set.id, 4),
        Map.get(file_set.metadata.digests, "sha256")
      ])

    original_filename = file_set.metadata.original_filename
    dest_location = %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
    s3_metadata = [original_filename: original_filename]

    Logger.info("Copying #{original_filename} from #{src_location} to #{dest_location}")

    case ExAws.S3.put_object_copy(dest_bucket, dest_key, src_bucket, src_key, meta: s3_metadata)
         |> ExAws.request() do
      {:ok, _} -> {:ok, dest_location}
      {:error, {:http_error, _status, %{body: body}}} -> {:error, body}
      {:error, other} -> {:error, inspect(other)}
    end
  end
end
