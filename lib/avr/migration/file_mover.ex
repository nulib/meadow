defmodule AVR.Migration.FileMover do
  alias Meadow.Data.FileSets
  alias Meadow.Utils.AWS
  alias Meadow.Utils.Stream, as: StreamUtils

  require Logger

  @avr_derivative_bucket "avalon-derivatives-cfx3wj9"

  def process_all_file_set_files do
    AVR.Migration.list_avr_filesets()
    |> Task.async_stream(&process_file_set_files/1, timeout: :infinity)
    |> Stream.run()
  end

  def process_file_set_files(file_set) do
    file_set
    |> copy_preservation_file()
    |> copy_derivatives()
  end

  def copy_preservation_file(file_set) do
    with %{core_metadata: %{location: current_location}} <- file_set,
         preservation_location <- FileSets.preservation_location(file_set) do
      case maybe_copy(current_location, preservation_location) do
        :exists ->
          Logger.warn("[#{file_set.id}] Destination #{preservation_location} already exists")
          file_set

        :unknown_source ->
          Logger.warn("[#{file_set.id}] Unknown source location: #{current_location}")
          file_set

        {:ok, %{status_code: 200}} ->
          {:ok, result} =
            file_set
            |> FileSets.update_file_set(%{core_metadata: %{location: preservation_location}})

          result

        other ->
          Logger.warn("[#{file_set.id}] Failed to copy: #{inspect(other)}")
      end
    end
  end

  def copy_derivatives(%{derivatives: %{playlist: _}} = file_set) do
    Logger.warn("[#{file_set.id}] Skipping derivative copy because a playlist is already present")
    file_set
  end

  def copy_derivatives(file_set) do
    playlist =
      with %{host: dest_bucket, path: "/" <> dest_key_prefix} <-
             FileSets.streaming_uri_for(file_set) |> URI.parse(),
           "avr:" <> masterfile_id <- file_set.accession_number,
           prefix <- masterfile_id <> "/" do
        ExAws.S3.list_objects_v2(@avr_derivative_bucket, prefix: prefix)
        |> ExAws.stream!()
        |> Task.async_stream(
          fn %{key: src_key} ->
            with dest_key <- Path.join(dest_key_prefix, String.trim_leading(src_key, prefix)) do
              AWS.copy_object(dest_bucket, dest_key, @avr_derivative_bucket, src_key)
              ["s3://", dest_bucket, "/", dest_key] |> IO.iodata_to_binary()
            end
          end,
          timeout: :infinity
        )
        |> Stream.map(fn {:ok, val} -> val end)
        |> Stream.filter(&String.ends_with?(&1, ".m3u8"))
        |> Enum.to_list()
        |> Enum.sort_by(fn val ->
          cond do
            String.contains?(val, "high") -> 1
            String.contains?(val, "medium") -> 2
            String.contains?(val, "low") -> 3
            true -> 0
          end
        end)
        |> List.first()
      end

    derivatives = FileSets.add_derivative(file_set, :playlist, playlist)

    with {:ok, result} <- FileSets.update_file_set(file_set, %{derivatives: derivatives}) do
      result
    end
  end

  defp maybe_copy("s3://preservation-cfx3wj9/" <> _ = src, dest), do: copy_file(src, dest)
  defp maybe_copy("s3://stack-p-avr-masterfiles/" <> _ = src, dest), do: copy_file(src, dest)
  defp maybe_copy(_, _), do: :unknown_source

  defp copy_file(src, dest) do
    if StreamUtils.exists?(dest) do
      :exists
    else
      with %{host: src_bucket, path: "/" <> src_key} <- URI.parse(src),
           %{host: dest_bucket, path: "/" <> dest_key} <- URI.parse(dest) do
        AWS.copy_object(dest_bucket, dest_key, src_bucket, src_key)
      end
    end
  end
end
