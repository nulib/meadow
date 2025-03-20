defmodule Meadow.Events.FileSets.Cleanup do
  @moduledoc """
  Handler to clean up file set assets after records are deleted
  """

  alias Meadow.Config
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
    Logger.warning("Removing #{type} derivative at #{uri}")
    delete_s3_uri(uri)
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

    ExAws.S3.delete_object(Config.pyramid_bucket(), FileSets.vtt_location(id))
    |> ExAws.request()

    file_set_data
  end

  defp in_ingest_bucket(%{core_metadata: core_metadata}) do
    location = Map.get(core_metadata, "location")
    if location, do: URI.parse(location) |> Map.get(:host) == Config.ingest_bucket()
  end

  defp delete_s3_uri(uri, recursive \\ false)

  defp delete_s3_uri(uri, true) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(uri) do
      case ExAws.S3.head_bucket(bucket) |> ExAws.request() do
        {:error, {:http_error, 404, _}} ->
          :noop

        _ ->
          keys =
            ExAws.S3.list_objects(bucket, prefix: key)
            |> ExAws.stream!()
            |> Stream.map(& &1.key)

          ExAws.S3.delete_all_objects(bucket, keys)
          |> ExAws.request()
      end
    end
  end

  defp delete_s3_uri(uri, false) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(uri) do
      ExAws.S3.delete_object(bucket, key)
      |> ExAws.request()
    end
  end
end
