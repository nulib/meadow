defmodule Meadow.Events.FileSets.Cleanup do
  @moduledoc """
  Handler to clean up file set assets after records are deleted
  """

  alias Meadow.Config
  alias Meadow.AWS.S3
  alias Meadow.Data.FileSets

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  require Logger

  on_delete(:file_sets, %{}, [{__MODULE__, :handle_delete}], & &1)

  def handle_delete(%{name: name, old_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      clean_up!(record)
    end
  end

  defp clean_up!(file_set_data) do
    with_log_metadata(module: __MODULE__, id: file_set_data.id) do
      Logger.warning("Cleaning up assets for file set #{file_set_data.id}")

      file_set_data
      |> clean_derivatives!()
      |> clean_preservation_file!()
      |> clean_structural_metadata!()
      |> clean_annotations!()
    end
  end

  defp clean_derivatives!(file_set_data) do
    file_set_data.derivatives
    |> Enum.each(fn {type, location} ->
      Logger.info("Cleaning up #{type} derivative at #{location}")
      clean_derivative!(type, location)
    end)

    file_set_data
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

  defp clean_preservation_file!(
         %{id: id, core_metadata: %{"location" => location}} = file_set_data
       ) do
    if in_ingest_bucket(file_set_data) do
      Logger.warning("Leaving #{location} intact in the ingest bucket")
    else
      Logger.warning("Removing preservation file for #{id} at #{location}")
      delete_s3_uri(location)
    end

    file_set_data
  end

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

  defp in_ingest_bucket(%{core_metadata: core_metadata}) do
    location = Map.get(core_metadata, "location")
    if location, do: URI.parse(location) |> Map.get(:host) == Config.ingest_bucket()
  end

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
