defmodule Meadow.Utils.AWS.MultipartCopy do
  @moduledoc """
  Perform a multipart S3-to-S3 copy using ExAws
  """

  alias Meadow.Config
  alias Meadow.Utils.AWS

  import SweetXml, only: [sigil_x: 2]

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

    case ExAws.S3.head_object(src_bucket, src_object) |> AWS.request() do
      {:ok, %{status_code: 200, headers: headers}} ->
        content_length =
          headers
          |> Enum.into(%{})
          |> Map.get("Content-Length")
          |> Integer.parse()
          |> Tuple.to_list()
          |> List.first()

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
  end

  defp copy_s3_object(%__MODULE__{content_length: length} = op) when length > @threshold do
    Logger.debug("File size #{length} > #{@threshold}; using MultipartUpload")

    op
    |> initiate_upload()
    |> upload_chunks()
    |> complete_upload()
  end

  defp copy_s3_object(%__MODULE__{content_length: length} = op) do
    Logger.debug("File size #{length} <= #{@threshold}; using CopyObject")

    ExAws.S3.put_object_copy(
      op.dest_bucket,
      op.dest_object,
      op.src_bucket,
      op.src_object,
      op.opts
    )
    |> AWS.request()
  end

  defp initiate_upload(%__MODULE__{} = op) do
    case ExAws.S3.initiate_multipart_upload(op.dest_bucket, op.dest_object, op.opts)
         |> AWS.request() do
      {:ok, %{body: %{upload_id: upload_id}, status_code: 200}} ->
        {:ok, op |> Map.put(:upload_id, upload_id)}

      other ->
        other
    end
  end

  defp upload_chunks({:ok, %__MODULE__{} = op}) do
    with chunk_size <- extract_chunk_size(op),
         chunks <- Float.ceil(op.content_length / chunk_size) |> trunc() do
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
  end

  defp upload_chunks({:error, payload}), do: {:error, payload}

  defp complete_upload({:error, %__MODULE__{} = op}) do
    Logger.debug("Error encountered. Aborting multipart upload.")

    ExAws.S3.abort_multipart_upload(op.dest_bucket, op.dest_object, op.upload_id)
    |> AWS.request()
  end

  defp complete_upload({:error, other}) do
    Logger.debug("Error encountered. #{inspect(other)}")
    {:error, parse_error(other)}
  end

  defp complete_upload({parts, %__MODULE__{} = op}) do
    Logger.debug("Completing multipart upload.")

    ExAws.S3.complete_multipart_upload(op.dest_bucket, op.dest_object, op.upload_id, parts)
    |> Map.put(:parser, &parse_complete_result/1)
    |> AWS.request()
  end

  defp upload_chunk(%__MODULE__{} = op, chunk) do
    with chunk_size <- extract_chunk_size(op),
         first_byte <- (chunk - 1) * chunk_size,
         last_byte <- min(op.content_length, first_byte + chunk_size) - 1 do
      result =
        %ExAws.Operation.S3{
          body: "",
          bucket: op.dest_bucket,
          headers: %{
            "x-amz-copy-source-range" => "bytes=#{first_byte}-#{last_byte}",
            "x-amz-copy-source" => ["", op.src_bucket, op.src_object] |> Enum.join("/")
          },
          http_method: :put,
          parser: &parse_copy_part_result/1,
          path: op.dest_object,
          params: %{
            "partNumber" => chunk,
            "uploadId" => op.upload_id
          },
          service: :s3,
          stream_builder: nil
        }
        |> AWS.request()

      case result do
        {:ok, %{status_code: 200, body: %{e_tag: etag}}} -> {:ok, String.replace(etag, ~s'"', "")}
        other -> {:error, other}
      end
    end
  end

  defp parse_complete_result({:ok, %{body: xml} = resp}) do
    parsed_body =
      SweetXml.xpath(xml, ~x"//CompleteMultipartUploadResult",
        bucket: ~x"./Bucket/text()"s,
        key: ~x"./Key/text()"s,
        location: ~x"./Location/text()"s,
        e_tag: ~x"./ETag/text()"s
      )

    {:ok, %{resp | body: parsed_body}}
  end

  defp parse_complete_result({:error, error}) do
    Logger.warn("Error in multipart copy: #{inspect(error)}")
    {:error, error}
  end

  defp parse_complete_result(response) do
    Logger.warn("Unknown response in multipart copy: #{inspect(response)}")
    {:unknown, response}
  end

  defp parse_copy_part_result({:ok, %{body: xml} = resp}) do
    parsed_body =
      SweetXml.xpath(xml, ~x"//CopyPartResult",
        e_tag: ~x"./ETag/text()"s,
        last_modified: ~x"./LastModified/text()"s
      )

    {:ok, %{resp | body: parsed_body}}
  end

  defp parse_error({:http_error, _, %{body: xml} = resp}) do
    parsed_body =
      SweetXml.xpath(xml, ~x"//Error",
        code: ~x"./Code/text()"s,
        message: ~x"./Message/text()"s,
        bucket: ~x"./BucketName/text()"s,
        request_id: ~x"./RequestId/text()"s,
        host_id: ~x"./HostId/text()"s
      )

    %{resp | body: parsed_body}
  end

  defp parse_error(error), do: error

  defp extract_chunk_size(%__MODULE__{} = op), do: Keyword.get(op.opts, :chunk_size, @chunk_size)
end
