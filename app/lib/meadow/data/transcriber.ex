defmodule Meadow.Data.Transcriber do
  @moduledoc """
  Facilitates image transcription by invoking the configured AWS Bedrock model.
  """

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.HTTP
  alias Meadow.Utils.AWS.BedrockStream

  require Logger

  @default_max_tokens 1024
  @image_variant "full/!1024,1024/0/default.jpg"
  @default_model "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
  @image_request_headers [{"Accept", "image/jpeg"}]
  @image_request_opts [follow_redirect: true, recv_timeout: 30_000]

  @doc """
  Retrieve a transcription for the representative image associated with the given file set.

  Returns `{:ok, %{text: text, raw: response, streamed_chunks: chunks}}` on success or
  `{:error, reason}` when the request cannot be completed.

  ## Options

    * `:prompt` - Override the default prompt sent with the request.
    * `:max_tokens` - Limit the generation length (defaults to #{@default_max_tokens}).

  Note: This function uses Bedrock's streaming API for better performance and real-time feedback.
  """
  @spec transcribe(binary(), keyword()) ::
          {:ok, %{text: binary(), raw: map(), streamed_chunks: list()}} | {:error, term()}
  def transcribe(file_set_id, opts \\ []) when is_binary(file_set_id) do
    previous_metadata = Logger.metadata()
    Logger.metadata(file_set_id: file_set_id)
    Logger.info("Starting transcription job")

    result =
      with {:ok, file_set} <- fetch_file_set(file_set_id),
           {:ok, base_url} <- representative_image_url(file_set),
           {:ok, encoded_image, mime_type} <- fetch_base64_image(base_url),
           {:ok, model_id} <- transcriber_model(),
           request_body <- build_request_body(file_set.id, encoded_image, mime_type, opts),
           {:ok, response, chunks} <- invoke_model_with_stream(model_id, request_body) do
        Logger.info("Completed transcription job")
        text = transcription_text(response, chunks)
        {:ok, %{text: text, raw: response, streamed_chunks: chunks}}
      else
        {:error, reason} = error ->
          Logger.error("Transcription job failed", reason: inspect(reason))
          error
      end

    Logger.reset_metadata()
    Logger.metadata(previous_metadata)
    result
  end

  defp fetch_file_set(file_set_id) do
    case FileSets.get_file_set(file_set_id) do
      %FileSet{} = file_set ->
        Logger.debug("Resolved file set for transcription")
        {:ok, file_set}

      nil ->
        Logger.warning("File set not found for transcription")
        {:error, {:file_set_not_found, file_set_id}}
    end
  end

  defp representative_image_url(%FileSet{} = file_set) do
    case FileSets.representative_image_url_for(file_set) do
      nil ->
        Logger.warning("No representative image available for transcription",
          file_set_id: file_set.id
        )

        {:error, {:no_representative_image, file_set.id}}

      url ->
        Logger.debug("Resolved IIIF base URL", base_url: url)
        {:ok, url}
    end
  end

  defp fetch_base64_image(base_url) do
    base_url
    |> build_image_url()
    |> HTTP.get(@image_request_headers, @image_request_opts)
    |> case do
      {:ok, %{status_code: 200, body: body, headers: headers}} ->
        encoded = Base.encode64(body)
        {:ok, encoded, header_value(headers, "content-type") || "image/jpeg"}

      {:ok, %{status_code: status} = response} ->
        Logger.warning("Failed to fetch IIIF image",
          status: status,
          url: base_url,
          response: Map.get(response, :body)
        )

        {:error, {:image_fetch_failed, status, Map.get(response, :body)}}

      {:error, reason} ->
        Logger.warning("HTTP error fetching IIIF image", url: base_url, reason: inspect(reason))
        {:error, {:image_fetch_error, reason}}
    end
  end

  defp transcriber_model do
    Application.get_env(:meadow, :transcriber_model, @default_model)
    |> case do
      model when is_binary(model) and byte_size(model) > 0 ->
        {:ok, model}

      nil ->
        {:ok, @default_model}

      other ->
        {:error, {:invalid_transcriber_model, other}}
    end
  end

  defp build_request_body(file_set_id, encoded_image, mime_type, opts) do
    prompt = opts |> Keyword.get(:prompt, default_prompt(file_set_id))

    max_tokens =
      opts
      |> Keyword.get(:max_tokens, @default_max_tokens)
      |> normalize_max_tokens()

    # Determine image format from MIME type
    image_format =
      case mime_type do
        "image/jpeg" -> "jpeg"
        "image/jpg" -> "jpeg"
        "image/png" -> "png"
        "image/gif" -> "gif"
        "image/webp" -> "webp"
        _ -> "jpeg"
      end

    %{
      "messages" => [
        %{
          "role" => "user",
          "content" => [
            %{
              "image" => %{
                "format" => image_format,
                "source" => %{
                  "bytes" => encoded_image
                }
              }
            },
            %{
              "text" => prompt
            }
          ]
        }
      ],
      "toolConfig" => %{
        "tools" => [
          %{
            "toolSpec" => %{
              "name" => "provide_transcription",
              "description" =>
                "Provide the exact transcribed text from the image without any preamble or explanation.",
              "inputSchema" => %{
                "json" => %{
                  "type" => "object",
                  "properties" => %{
                    "transcribed_text" => %{
                      "type" => "string",
                      "description" => "The exact text transcribed from the image"
                    }
                  },
                  "required" => ["transcribed_text"]
                }
              }
            }
          }
        ],
        "toolChoice" => %{
          "tool" => %{
            "name" => "provide_transcription"
          }
        }
      },
      "inferenceConfig" => %{
        "maxTokens" => max_tokens
      }
    }
  end

  defp default_prompt(file_set_id) do
    """
    Review the provided digitized image for Meadow file set #{file_set_id}.
    Extract every legible piece of text, preserving line breaks when helpful.
    Use the provide_transcription tool to return the transcribed text.
    """
    |> String.trim()
  end

  defp invoke_model_with_stream(model_id, body) do
    Logger.info("Invoking Bedrock streaming endpoint", model_id: model_id)
    operation = build_stream_operation(model_id, body)
    invoke_with_stream(operation, model_id)
  end

  defp build_stream_operation(model_id, body) do
    post =
      %ExAws.Operation.JSON{
        data: body,
        headers: [{"Content-Type", "application/json"}],
        http_method: :post,
        path: "/model/#{model_id}/converse-stream",
        service: :"bedrock-runtime"
      }

    %{post | stream_builder: &BedrockStream.stream_objects!(post, nil, &1)}
  end

  defp invoke_with_stream(operation, model_id) do
    stream = ExAws.stream!(operation, service_override: :bedrock)
    consume_stream(model_id, stream)
  rescue
    error ->
      Logger.error("Streaming invocation failed",
        model_id: model_id,
        error: Exception.message(error)
      )

      {:error, {:bedrock_stream_failed, error}}
  end

  defp consume_stream(model_id, stream) do
    {chunks, final_response} = reduce_stream(stream)

    case final_response do
      nil ->
        Logger.debug("Streaming completed without final response payload", model_id: model_id)
        {:ok, %{}, Enum.reverse(chunks)}

      response ->
        Logger.debug("Streaming completed with final payload", model_id: model_id)
        {:ok, response, Enum.reverse(chunks)}
    end
  end

  defp reduce_stream(stream) do
    Enum.reduce(stream, {[], nil}, fn
      {:chunk, chunk}, {acc, _last} ->
        Logger.debug("Received stream chunk", keys: Map.keys(chunk))
        {[chunk | acc], chunk}

      {:bad_chunk, data, reason}, {acc, last} ->
        Logger.warning("Malformed stream chunk",
          reason: inspect(reason),
          data_preview: binary_part(data, 0, min(100, byte_size(data)))
        )

        {acc, last}

      {:incomplete_chunk, _} = chunk, {acc, last} ->
        Logger.debug("Incomplete stream chunk encountered")
        {[chunk | acc], last}

      other, {acc, last} ->
        Logger.debug("Unhandled stream message", message: inspect(other))
        {acc, last}
    end)
  end

  defp transcription_text(response, []), do: extract_primary_text(response)

  defp transcription_text(response, chunks) do
    case extract_primary_text(response) do
      "" -> extract_text_from_chunks(chunks)
      text -> text
    end
  end

  # ConverseStream final events (text extracted from chunks, not final payload)
  defp extract_primary_text(%{"messageStop" => _}), do: ""
  defp extract_primary_text(%{"metadata" => _}), do: ""
  defp extract_primary_text(%{"usage" => _}), do: ""
  defp extract_primary_text(%{"metrics" => _}), do: ""
  defp extract_primary_text(_), do: ""

  defp extract_text_from_chunks(chunks) do
    # Accumulate tool use input chunks
    json_chunks =
      chunks
      |> Enum.reduce([], &gather_stream_text/2)
      |> Enum.reverse()
      |> Enum.join()

    # Try to parse as JSON tool input
    case Jason.decode(json_chunks) do
      {:ok, %{"transcribed_text" => text}} ->
        String.trim(text)

      _ ->
        # Fallback to treating as plain text (for backward compatibility)
        String.trim(json_chunks)
    end
  end

  # ConverseStream with tool use: delta.toolUse.input is a JSON string chunk
  defp gather_stream_text(
         %{"delta" => %{"toolUse" => %{"input" => input}}},
         acc
       )
       when is_binary(input) do
    # Tool use input is streamed as JSON string chunks
    [input | acc]
  end

  # ConverseStream text delta: delta.text
  defp gather_stream_text(
         %{"delta" => %{"text" => text}},
         acc
       )
       when is_binary(text) do
    [text | acc]
  end

  defp gather_stream_text(_other, acc), do: acc

  defp build_image_url(base_url) do
    base_url
    |> ensure_trailing_slash()
    |> Kernel.<>(@image_variant)
  end

  defp ensure_trailing_slash(url) do
    if String.ends_with?(url, "/"), do: url, else: url <> "/"
  end

  defp header_value(headers, key) do
    downcased = String.downcase(key)

    headers
    |> Enum.find_value(fn
      {header_key, value} when is_binary(header_key) ->
        if String.downcase(header_key) == downcased, do: value

      {header_key, value} when is_atom(header_key) ->
        if Atom.to_string(header_key) |> String.downcase() == downcased, do: value

      _ ->
        nil
    end)
  end

  defp normalize_max_tokens(value) when is_integer(value) and value > 0, do: value

  defp normalize_max_tokens(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} when int > 0 -> int
      _ -> @default_max_tokens
    end
  end

  defp normalize_max_tokens(_), do: @default_max_tokens
end
