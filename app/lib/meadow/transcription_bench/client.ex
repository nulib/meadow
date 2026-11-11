defmodule Meadow.TranscriptionBench.Client do
  @moduledoc """
  What a bench transcription does to the outside world: fetch a file set's image from
  the IIIF server and send it to a Bedrock model.

  Both follow `Meadow.Data.Transcriber`, so that a result here is what a production
  transcription with the same prompt and model would be: the image is the file set's
  representative image at `full/^!N,N/0/default.jpg` (N is 2048 in production), fetched
  with a superuser DC API token, and the request goes out through
  `Meadow.AWS.Bedrock.converse_stream/2`.
  """

  alias Meadow.AWS.Bedrock
  alias Meadow.HTTP
  alias Meadow.TranscriptionBench.ImageSize
  alias Meadow.Utils.DCAPI

  require Logger

  @min_edge 256
  @max_edge 8000
  @default_edge 2048
  @max_tokens 64_000
  @request_opts [redirect: true, receive_timeout: 30_000]

  @type image :: %{
          bytes: binary(),
          format: String.t(),
          sent: {pos_integer(), pos_integer()},
          processed: {pos_integer(), pos_integer()},
          full: {pos_integer(), pos_integer()}
        }

  @doc """
  The image a variant sends a model for an IIIF image URL, with its size, the size the
  model processes it at (see `Meadow.TranscriptionBench.ImageSize`) and the size of the
  full image (the Canvas the regions are drawn on).

  A variant's `imageFit` decides what is sent:

    * `"production"` (the default) - the image as the transcriber fetches it, longest
      edge `maxEdge`. A model whose limits it exceeds resizes it, and answers in pixels
      of the resized image.
    * `"model"` - that image resized by the IIIF server to what the model would make of
      it, so that nothing is resized out of sight and the size sent is the size
      processed.
  """
  @spec fetch_image(String.t(), map(), String.t()) :: {:ok, image()} | {:error, String.t()}
  def fetch_image(base_url, variant, model) do
    base_url = String.trim_trailing(base_url, "/")
    edge = variant |> Map.get("maxEdge") |> clamp(@min_edge, @max_edge, @default_edge)
    tier = ImageSize.tier(model, variant)

    with {:ok, headers} <- auth_headers(),
         {:ok, image} <- get_image(base_url, "^!#{edge},#{edge}", headers),
         {:ok, image} <- fit(image, base_url, headers, variant, tier) do
      {:ok,
       image
       |> Map.put(:processed, ImageSize.resized(image.sent, tier))
       |> Map.put(:full, full_size(base_url, headers) || image.sent)}
    end
  end

  defp fit(image, base_url, headers, %{"imageFit" => "model"}, tier) do
    case ImageSize.resized(image.sent, tier) do
      size when size == image.sent -> {:ok, image}
      {width, height} -> get_image(base_url, "!#{width},#{height}", headers)
    end
  end

  defp fit(image, _base_url, _headers, _variant, _tier), do: {:ok, image}

  defp get_image(base_url, size, headers) do
    url = URI.encode("#{base_url}/full/#{size}/0/default.jpg")
    opts = [{:headers, [{"Accept", "image/jpeg"} | headers]}, {:raw, true}] ++ @request_opts

    with {:ok, %{status: 200} = response} <- HTTP.get(url, opts),
         {:ok, sent} <- image_size(response.body) do
      {:ok, %{bytes: response.body, format: image_format(response), sent: sent}}
    else
      {:ok, %{status: status}} -> {:error, "The IIIF server answered #{status} for #{url}"}
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, reason} -> {:error, "Could not fetch #{url}: #{inspect(reason)}"}
    end
  end

  defp auth_headers do
    case DCAPI.token(300,
           scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
           is_superuser: true
         ) do
      {:ok, %{token: token}} -> {:ok, [{"Authorization", "Bearer #{token}"}]}
      {:error, reason} -> {:error, "Could not make a DC API token: #{inspect(reason)}"}
    end
  end

  defp image_size(body) do
    case Image.from_binary(body) do
      {:ok, image} -> {:ok, {Image.width(image), Image.height(image)}}
      _ -> {:error, "The IIIF server did not return an image"}
    end
  end

  defp image_format(response) do
    case Req.Response.get_header(response, "content-type") do
      ["image/png" <> _ | _] -> "png"
      ["image/gif" <> _ | _] -> "gif"
      ["image/webp" <> _ | _] -> "webp"
      _ -> "jpeg"
    end
  end

  # The full image's size, from info.json. Regions are kept as fractions, so a missing
  # info.json only costs the Canvas its true size.
  defp full_size(base_url, headers) do
    case HTTP.get(
           "#{base_url}/info.json",
           [{:headers, headers}, {:decode_body, false}] ++ @request_opts
         ) do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"width" => width, "height" => height}}
          when is_integer(width) and is_integer(height) ->
            {width, height}

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  @doc """
  The Converse request for a variant and the image sent. A variant is the map the
  dashboard sends, with its camelCase keys. Returns `{:error, message}` for JSON a
  variant got wrong.
  """
  @spec request_body(map(), image()) :: {:ok, map()} | {:error, String.t()}
  def request_body(variant, %{bytes: bytes, format: format, sent: size}) do
    with {:ok, tool_config} <- tool_config(variant, size),
         {:ok, additional} <- additional_fields(variant) do
      body =
        %{
          "messages" => [
            %{
              "role" => "user",
              "content" => [
                %{
                  "image" => %{"format" => format, "source" => %{"bytes" => Base.encode64(bytes)}}
                },
                %{"text" => fill(variant["prompt"], variant, size)}
              ]
            }
          ],
          "inferenceConfig" => inference_config(variant)
        }
        |> put_present("system", system(variant, size))
        |> put_present("toolConfig", tool_config)
        |> put_present("additionalModelRequestFields", additional)

      {:ok, body}
    end
  end

  defp inference_config(variant) do
    config = %{
      "maxTokens" => variant |> Map.get("maxTokens") |> clamp(1, @max_tokens, @max_tokens)
    }

    case variant["temperature"] do
      temperature when is_number(temperature) -> Map.put(config, "temperature", temperature)
      _ -> config
    end
  end

  defp system(variant, size) do
    case String.trim(variant["system"] || "") do
      "" -> nil
      _ -> [%{"text" => fill(variant["system"], variant, size)}]
    end
  end

  defp tool_config(%{"outputMode" => "tool"} = variant, size) do
    name = variant["toolName"] || ""

    case Jason.decode(fill(variant["toolSchema"], variant, size)) do
      {:ok, schema} when is_map(schema) and name != "" ->
        {:ok,
         %{
           "tools" => [
             %{
               "toolSpec" => %{
                 "name" => name,
                 "description" => fill(variant["toolDescription"], variant, size),
                 "inputSchema" => %{"json" => schema}
               }
             }
           ],
           "toolChoice" => tool_choice(variant["toolChoice"], name)
         }}

      {:ok, _} when name == "" ->
        {:error, "The tool has no name"}

      {:ok, _} ->
        {:error, "The tool schema is not a JSON object"}

      {:error, error} ->
        {:error, "The tool schema is not valid JSON: #{Exception.message(error)}"}
    end
  end

  defp tool_config(_variant, _size), do: {:ok, nil}

  defp tool_choice("tool", name), do: %{"tool" => %{"name" => name}}
  defp tool_choice("any", _name), do: %{"any" => %{}}
  defp tool_choice(_auto, _name), do: %{"auto" => %{}}

  defp additional_fields(variant) do
    case String.trim(variant["additionalFields"] || "") do
      "" ->
        {:ok, nil}

      json ->
        case Jason.decode(json) do
          {:ok, fields} when is_map(fields) ->
            {:ok, fields}

          {:ok, _} ->
            {:error, "Additional model request fields are not a JSON object"}

          {:error, error} ->
            {:error,
             "Additional model request fields are not valid JSON: #{Exception.message(error)}"}
        end
    end
  end

  # {{width}} and {{height}} are the size of the image sent, {{tool_name}} the tool.
  defp fill(template, variant, {width, height}) do
    (template || "")
    |> String.replace("{{width}}", to_string(width))
    |> String.replace("{{height}}", to_string(height))
    |> String.replace("{{tool_name}}", variant["toolName"] || "")
  end

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)

  defp clamp(value, low, high, _default) when is_integer(value),
    do: value |> max(low) |> min(high)

  defp clamp(value, low, high, _default) when is_float(value),
    do: clamp(round(value), low, high, nil)

  defp clamp(_value, _low, _high, default), do: default

  @doc "The request as it is kept with a result: everything but the image's bytes."
  def redact(body, model) do
    body
    |> update_in(["messages", Access.all(), "content", Access.all()], fn
      %{"image" => image} ->
        %{"image" => put_in(image, ["source", "bytes"], "<image bytes omitted>")}

      other ->
        other
    end)
    |> Map.put("modelId", model)
  end

  @doc """
  Send a Converse request and read the stream back into the tool input, the text, the
  reasoning, the stop reason and the token usage.
  """
  @spec converse(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def converse(model, body) do
    model
    |> Bedrock.converse_stream(body)
    |> Enum.reduce(
      %{tool_input: [], text: [], reasoning: [], stop_reason: nil, usage: nil, error: nil},
      &gather/2
    )
    |> case do
      %{error: nil} = out ->
        {:ok,
         %{
           tool_input: join(out.tool_input),
           text: join(out.text),
           reasoning: join(out.reasoning),
           stop_reason: out.stop_reason,
           usage: out.usage
         }}

      %{error: error} ->
        {:error, error}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp join(parts), do: parts |> Enum.reverse() |> IO.iodata_to_binary()

  defp gather({:chunk, %{"delta" => %{"toolUse" => %{"input" => input}}}}, out)
       when is_binary(input),
       do: %{out | tool_input: [input | out.tool_input]}

  defp gather({:chunk, %{"delta" => %{"text" => text}}}, out) when is_binary(text),
    do: %{out | text: [text | out.text]}

  defp gather({:chunk, %{"delta" => %{"reasoningContent" => %{"text" => text}}}}, out)
       when is_binary(text),
       do: %{out | reasoning: [text | out.reasoning]}

  defp gather({:chunk, %{"stopReason" => reason}}, out), do: %{out | stop_reason: reason}
  defp gather({:chunk, %{"usage" => usage}}, out), do: %{out | usage: usage}

  # An exception event in the stream (throttling, a model error) carries only a message.
  defp gather({:chunk, %{"message" => message} = chunk}, out)
       when is_binary(message) and map_size(chunk) <= 2,
       do: %{out | error: message}

  defp gather({:bad_chunk, _data, reason}, out) do
    Logger.warning("Malformed Bedrock stream chunk: #{inspect(reason)}")
    out
  end

  defp gather(_other, out), do: out
end
