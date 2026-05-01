defmodule Meadow.Data.Transcriber do
  @moduledoc """
  Facilitates image transcription by invoking the configured AWS Bedrock model.
  """

  @behaviour Meadow.Data.TranscriberBehaviour

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.HTTP
  alias Meadow.Utils.AWS, as: AWSUtils
  alias Meadow.Utils.AWS.BedrockStream
  alias Meadow.Utils.DCAPI

  require Logger

  @default_max_tokens 64_000
  @image_variant "full/^!2048,2048/0/default.jpg"
  @default_model "us.anthropic.claude-sonnet-4-6"
  @image_request_headers [{"Accept", "image/jpeg"}]
  @image_request_opts [redirect: true, receive_timeout: 30_000, raw: true]

  @doc """
  Retrieve a transcription for the representative image associated with the given file set.

  Returns `{:ok, %{text: text, raw: response, streamed_chunks: chunks}}` on success or
  `{:error, reason}` when the request cannot be completed.

  ## Options

    * `:prompt` - Override the default prompt sent with the request.
    * `:max_tokens` - Limit the generation length (defaults to #{@default_max_tokens}).

  Note: This function uses Bedrock's streaming API for better performance and real-time feedback.
  """
  @impl Meadow.Data.TranscriberBehaviour
  def transcribe(file_set_id, opts \\ []) when is_binary(file_set_id) do
    previous_metadata = Logger.metadata()
    Logger.metadata(id: file_set_id)
    Logger.info("Starting transcription job")

    result =
      with {:ok, file_set} <- fetch_file_set(file_set_id),
           {:ok, base_url} <- representative_image_url(file_set),
           {:ok, encoded_image, mime_type} <- fetch_base64_image(base_url),
           {:ok, model_id} <- transcriber_model(),
           request_body <- build_request_body(file_set.id, encoded_image, mime_type, opts),
           {:ok, response, chunks} <- invoke_model_with_stream(model_id, request_body) do
        Logger.info("Completed transcription job")
        %{text: text, languages: languages} = transcription_text(response, chunks)
        log_metrics(response)
        {:ok, %{text: text, languages: languages, raw: response, streamed_chunks: chunks}}
      else
        {:error, reason} = error ->
          Logger.error("Transcription job failed: #{inspect(reason)}")
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
        Logger.warning(
          "No representative image available for transcription in FileSet #{file_set.id}"
        )

        {:error, {:no_representative_image, file_set.id}}

      url ->
        Logger.debug("Resolved IIIF base URL: #{url}")
        {:ok, url}
    end
  end

  defp fetch_base64_image(base_url) do
    headers =
      with {:ok, %{token: token}} <-
             DCAPI.token(300,
               scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
               is_superuser: true
             ) do
        [{"Authorization", "Bearer #{token}"} | @image_request_headers]
        |> Enum.into(%{})
      end

    base_url
    |> build_image_url()
    |> HTTP.get([{:headers, headers} | @image_request_opts])
    |> case do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        encoded = Base.encode64(body)
        {:ok, encoded, header_value(headers, "content-type") || "image/jpeg"}

      {:ok, %{status: status} = response} ->
        Logger.warning(
          "Failed to fetch IIIF image #{base_url}: HTTP #{status} #{inspect(response)}"
        )

        {:error, {:image_fetch_failed, status, Map.get(response, :body)}}

      {:error, reason} ->
        Logger.warning("HTTP error fetching IIIF image #{base_url}: #{inspect(reason)}")
        {:error, {:image_fetch_error, reason}}
    end
  end

  defp transcriber_model do
    Config.ai(:transcriber_model, @default_model)
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
              "name" => "provide_exact_transcription",
              "description" =>
                "Transcribe only the intentional recto (front-side) text from a document image. " <>
                  "EXCLUDE any mirrored, reversed, or bleed-through text visible from the verso (back side) — " <>
                  "such text appears fainter, reads right-to-left, and sits between or behind primary lines; treat it as paper texture. " <>
                  "EXCLUDE color calibration targets, color bars, rulers, and scanning artifacts. " <>
                  "EXCLUDE cataloger annotations — handwritten identifiers (typically in pencil) " <>
                  "consisting of uppercase letters, digits, and underscores in a structured pattern " <>
                  "(e.g., \"BFMF_B25_F04_034\"). These are archival control numbers added after the fact, " <>
                  "not part of the original document. " <>
                  "Blank pages (including blank versos) should be reported with transcribed_text set to \"[blank page]\".",
              "inputSchema" => %{
                "json" => %{
                  "type" => "object",
                  "properties" => %{
                    "transcribed_text" => %{
                      "type" => "string",
                      "description" =>
                        "The full and exact text from the front (recto) of the document, " <>
                          "preserving original line breaks and top-to-bottom, left-to-right order. " <>
                          "Do NOT include reversed or mirrored bleed-through text from the verso, " <>
                          "color bars, rulers, or any scanning artifact. " <>
                          "Do NOT add bracketed placeholders like [reversed text] or [illegible] " <>
                          "for excluded bleed-through content. Never abbreviate or truncate."
                    },
                    "detected_languages" => %{
                      "type" => "array",
                      "items" => %{"type" => "string"},
                      "description" =>
                        "ISO 639 language codes for languages detected in the transcribed recto text (e.g., [\"en\", \"fr\"])"
                    }
                  },
                  "required" => ["transcribed_text", "detected_languages"]
                }
              }
            }
          }
        ],
        "toolChoice" => %{
          "tool" => %{
            "name" => "provide_exact_transcription"
          }
        }
      },
      "inferenceConfig" => %{
        "maxTokens" => max_tokens,
        "temperature" => 0
      }
    }
  end

  defp default_prompt(_file_set_id) do
    """
    Use the provide_exact_transcription tool to transcribe this image.

    WHAT TO EXCLUDE (do this first, before anything else):
    - Mirrored, reversed, or horizontally-flipped text that is visible because it
      has bled through or shown through from the reverse side of the paper. This
      text typically appears fainter or lighter than the primary writing, reads
      right-to-left, and may sit between or behind the primary lines. Treat it as
      part of the paper texture. Do NOT transcribe it. Do NOT note its presence.
      Do NOT add bracketed placeholders like [reversed text] or [illegible].
    - Color calibration targets, color bars, rulers, and scanning artifacts.
      These are never part of the resource.
    - Cataloger annotations: handwritten identifiers, almost always in pencil,
      made up of uppercase letters, digits, and underscores in a structured
      pattern such as `BFMF_B25_F04_034` or `MS_017_B02`. These are archival
      control numbers added by staff after the fact and are NOT part of the
      resource. Do not transcribe them and do not note their presence.

    WHAT TO TRANSCRIBE:
    Provide a FULL and EXACT transcription of the text intentionally written or
    printed on the front (recto) of the image — every column, heading, caption,
    and legible mark, exactly as it appears. Preserve line breaks when they
    clarify structure and keep the original order (top-to-bottom, left-to-right).
    Also detect the language(s) used.

    Never abbreviate, summarize, or truncate. You have a 64K output token limit,
    so there is NO EXCUSE for omitting any recto text. Blank pages — including
    blank versos — should be transcribed simply as [blank page].
    """
    |> String.trim()
  end

  defp invoke_model_with_stream(model_id, body) do
    Logger.info("Invoking Bedrock streaming endpoint")
    operation = build_stream_operation(model_id, body)
    invoke_with_stream(operation)
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

  defp invoke_with_stream(operation) do
    ExAws.stream!(operation, service_override: :bedrock)
    |> consume_stream()
  rescue
    error ->
      Logger.error("Streaming invocation failed: #{Exception.message(error)}")
      {:error, {:bedrock_stream_failed, error}}
  end

  defp consume_stream(stream) do
    {chunks, final_response} = reduce_stream(stream)

    case final_response do
      nil ->
        Logger.debug("Streaming completed without final response payload")
        {:ok, %{}, Enum.reverse(chunks)}

      response ->
        Logger.debug("Streaming completed with final payload")
        {:ok, response, Enum.reverse(chunks)}
    end
  end

  defp reduce_stream(stream) do
    Enum.reduce(stream, {[], nil}, fn
      {:chunk, chunk}, {acc, _last} ->
        Logger.debug("Received stream chunk")
        {[chunk | acc], chunk}

      {:bad_chunk, data, reason}, {acc, last} ->
        preview = binary_part(data, 0, min(100, byte_size(data)))
        Logger.warning("Malformed stream chunk (#{inspect(reason)}): #{inspect(preview)}...")

        {acc, last}

      {:incomplete_chunk, _} = chunk, {acc, last} ->
        Logger.debug("Incomplete stream chunk encountered")
        {[chunk | acc], last}

      other, {acc, last} ->
        Logger.debug("Unhandled stream message: #{inspect(other)}")
        {acc, last}
    end)
  end

  defp transcription_text(response, []), do: extract_transcription_data(response)

  defp transcription_text(response, chunks) do
    case extract_transcription_data(response) do
      %{text: ""} -> extract_data_from_chunks(chunks)
      data -> data
    end
  end

  # ConverseStream final events carry metadata only; text comes from chunk accumulation.
  defp extract_transcription_data(_), do: %{text: "", languages: []}

  defp extract_data_from_chunks(chunks) do
    json_chunks =
      chunks
      |> Enum.reduce([], &gather_stream_text/2)
      |> Enum.reverse()
      |> Enum.join()

    case Jason.decode(json_chunks) do
      {:ok, %{"transcribed_text" => text, "detected_languages" => languages}} ->
        %{text: String.trim(text), languages: languages}

      {:ok, %{"transcribed_text" => text}} ->
        %{text: String.trim(text), languages: ["en"]}

      _ ->
        %{text: String.trim(json_chunks), languages: ["en"]}
    end
  end

  # ConverseStream with tool use: delta.toolUse.input is a JSON string chunk
  defp gather_stream_text(
         %{"delta" => %{"toolUse" => %{"input" => input}}},
         acc
       )
       when is_binary(input) do
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
    |> URI.encode()
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

  defp log_metrics(%{"usage" => usage}) do
    {:ok, model} = transcriber_model()

    message = %{
      source: __MODULE__,
      model: model,
      tokens: usage
    }

    AWSUtils.log_metrics(message)
  end

  defp log_metrics(_), do: :noop
end
