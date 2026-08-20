defmodule Meadow.Events.FileSets.Cleanup do
  @moduledoc """
  Handler to clean up file set assets after records are deleted.

  A file set's preservation location and derivatives live in their own
  tables, whose rows are cascade-deleted with the file set and arrive as
  their own delete events. Each handler checks that the owning file set is
  really gone before touching S3, because the same rows are also replaced
  (deleted and reinserted) during ordinary metadata updates.
  """

  alias Meadow.Config
  alias Meadow.AWS.S3
  alias Meadow.Data.FileSets

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  require Logger

  on_event(:all, fn events -> Enum.each(events, &handle_event/1) end)

  def handle_event(%{type: :delete, name: :file_sets} = event), do: handle_delete(event)

  def handle_event(%{type: :delete, name: :file_set_core_metadata} = event),
    do: handle_core_metadata_delete(event)

  def handle_event(%{type: :delete, name: :file_set_derivatives} = event),
    do: handle_derivative_delete(event)

  def handle_event(_event), do: :noop

  def handle_delete(%{name: name, old_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      clean_up!(record)
    end
  end

  def handle_core_metadata_delete(%{name: name, old_record: record}) do
    if file_set_gone?(record.file_set_id) do
      with_log_metadata module: __MODULE__, id: record.file_set_id, name: name do
        clean_preservation_file!(record)
      end
    end
  end

  def handle_derivative_delete(%{name: name, old_record: record}) do
    if file_set_gone?(record.file_set_id) do
      with_log_metadata module: __MODULE__, id: record.file_set_id, name: name do
        Logger.info("Cleaning up #{record.kind} derivative at #{record.location}")
        clean_derivative!(record.kind, record.location)
      end
    end
  end

  defp file_set_gone?(file_set_id), do: is_nil(FileSets.get_file_set(file_set_id))

  defp clean_up!(file_set_data) do
    with_log_metadata(module: __MODULE__, id: file_set_data.id) do
      Logger.warning("Cleaning up assets for file set #{file_set_data.id}")

      file_set_data
      |> clean_structural_metadata!()
      |> clean_annotations!()
    end
  end

  defp clean_derivative!(:playlist, "s3://" <> _ = playlist) do
    with stream_base <- Path.dirname(playlist) <> "/" do
      Logger.warning("Removing streaming files from #{stream_base}")
      delete_s3_uri(stream_base, true)
    end
  end

  defp clean_derivative!(type, "s3://" <> _ = uri) do
    if URI.parse(uri) |> Map.get(:host) == Config.ingest_bucket() do
      Logger.warning("Not removing #{type} derivative #{uri} because it is in the ingest bucket.")
    else
      Logger.warning("Removing #{type} derivative at #{uri}")
      delete_s3_uri(uri)
    end
  end

  defp clean_derivative!(_, _), do: :ok

  defp clean_preservation_file!(%{file_set_id: id, location: location} = core_metadata)
       when is_binary(location) do
    if in_ingest_bucket(core_metadata) do
      Logger.warning("Leaving #{location} intact in the ingest bucket")
    else
      Logger.warning("Removing preservation file for #{id} at #{location}")
      delete_s3_uri(location)
    end

    core_metadata
  end

  defp clean_preservation_file!(core_metadata), do: core_metadata

  defp clean_structural_metadata!(%{id: id} = file_set_data) do
    Logger.warning("Removing structural metadata for #{id}")

    S3.delete_object(Config.pyramid_bucket(), FileSets.vtt_location(id))

    file_set_data
  end

  defp clean_annotations!(%{id: file_set_id} = file_set_data) do
    annotations = FileSets.list_annotations(file_set_id)

    Enum.each(annotations, fn annotation ->
      if annotation.s3_location do
        Logger.warning("Removing annotation #{annotation.type} at #{annotation.s3_location}")
        delete_s3_uri(annotation.s3_location)
      end
    end)

    file_set_data
  end

  defp in_ingest_bucket(%{location: location}) when is_binary(location),
    do: URI.parse(location) |> Map.get(:host) == Config.ingest_bucket()

  defp in_ingest_bucket(_), do: false

  defp delete_s3_uri(uri, recursive \\ false)

  defp delete_s3_uri(uri, true) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(uri) do
      if S3.bucket_exists?(bucket) do
        bucket
        |> S3.stream_objects(prefix: key)
        |> Stream.map(& &1.key)
        |> then(&S3.delete_objects(bucket, &1))
      else
        :noop
      end
    end
  end

  defp delete_s3_uri(uri, false) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(uri) do
      S3.delete_object(bucket, key)
    end
  end
end
