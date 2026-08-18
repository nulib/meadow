defmodule Meadow.Utils.AWS.MultipartCopy do
  @moduledoc """
  Perform a multipart S3-to-S3 copy
  """

  alias Meadow.AWS.S3
  alias Meadow.Config

  require Logger

  defstruct dest_bucket: nil,
            dest_object: nil,
            src_bucket: nil,
            src_object: nil,
            opts: [],
            content_length: nil,
            upload_id: nil

  @chunk_size 524_288_000
  @threshold 20_971_520

  @doc """
  Copy an object, automatically switching to multipart copy if the source object
  is larger than 5GB.
  """
  def copy_object(dest_bucket, dest_object, src_bucket, src_object, opts \\ []) do
    Logger.debug("Copying s3://#{src_bucket}/#{src_object} to s3://#{dest_bucket}/#{dest_object}")

    case S3.head_object(src_bucket, src_object) do
      {:ok, %{content_length: content_length}} ->
        %__MODULE__{
          dest_bucket: dest_bucket,
          dest_object: dest_object,
          src_bucket: src_bucket,
          src_object: src_object,
          opts: opts,
          content_length: content_length
        }
        |> copy_s3_object()

      other ->
        other
    end

    case S3.head_object(dest_bucket, dest_object) do
      {:ok, anything} ->
        {:ok, anything}

      other ->
        Logger.error("Multipart copy failed: #{inspect(other)}")
        {:error, "Multipart copy failed: #{inspect(other)}"}
    end
  end

  defp copy_s3_object(%__MODULE__{content_length: length} = op)
       when is_integer(length) and length > @threshold do
    Logger.info("File size #{length} > #{@threshold}; using MultipartUpload")

    op
    |> initiate_upload()
    |> upload_chunks()
    |> complete_upload()
  end

  defp copy_s3_object(%__MODULE__{content_length: length} = op) do
    Logger.info("File size #{length} <= #{@threshold}; using CopyObject")

    S3.copy_object(op.dest_bucket, op.dest_object, op.src_bucket, op.src_object, op.opts)
  end

  defp initiate_upload(%__MODULE__{} = op) do
    case S3.create_multipart_upload(op.dest_bucket, op.dest_object, op.opts) do
      {:ok, upload_id} -> {:ok, op |> Map.put(:upload_id, upload_id)}
      other -> other
    end
  end

  defp upload_chunks({:ok, %__MODULE__{} = op}) do
    chunk_size = extract_chunk_size(op)
    chunks = Float.ceil(op.content_length / chunk_size) |> trunc()
    Logger.debug("Splitting into #{chunks} #{chunk_size}-byte parts")

    parts =
      1..chunks
      |> Task.async_stream(&upload_chunk(op, &1),
        timeout: :infinity,
        max_concurrency: Config.multipart_upload_concurrency()
      )
      |> Enum.to_list()

    case parts |> Enum.map(fn {status, _} -> status end) |> Enum.uniq() do
      [:ok] ->
        {parts
         |> Enum.with_index(1)
         |> Enum.map(fn
           {{:ok, {:ok, etag}}, part_number} -> {part_number, etag}
         end), op}

      _ ->
        {:error, op}
    end
  end

  defp upload_chunks({:error, payload}), do: {:error, payload}

  defp complete_upload({:error, %__MODULE__{} = op}) do
    Logger.error("Error encountered. Aborting multipart upload.")
    S3.abort_multipart_upload(op.dest_bucket, op.dest_object, op.upload_id)
  end

  defp complete_upload({:error, other}) do
    Logger.error("Error encountered. #{inspect(other)}")
    {:error, other}
  end

  defp complete_upload({parts, %__MODULE__{} = op}) do
    Logger.info("Completing multipart upload.")
    S3.complete_multipart_upload(op.dest_bucket, op.dest_object, op.upload_id, parts)
  end

  defp upload_chunk(%__MODULE__{} = op, chunk) do
    Logger.debug("Uploading chunk #{chunk}")

    with chunk_size <- extract_chunk_size(op),
         first_byte <- (chunk - 1) * chunk_size,
         last_byte <- min(op.content_length, first_byte + chunk_size) - 1 do
      S3.upload_part_copy(
        op.dest_bucket,
        op.dest_object,
        op.upload_id,
        chunk,
        {op.src_bucket, op.src_object},
        "bytes=#{first_byte}-#{last_byte}",
        receive_timeout: Config.multipart_upload_timeout()
      )
    end
  end

  defp extract_chunk_size(%__MODULE__{} = op), do: Keyword.get(op.opts, :chunk_size, @chunk_size)
end
