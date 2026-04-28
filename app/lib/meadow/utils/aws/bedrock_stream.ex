defmodule Meadow.Utils.AWS.BedrockStream do
  @moduledoc """
  Minimal helper for consuming AWS Bedrock streaming responses without the
  external `ex_aws_bedrock` dependency.

  It signs the request using `ExAws.Auth`, opens a streaming connection via
  `:hackney`, and emits decoded event stream payloads.
  """

  alias ExAws.Request.Url
  alias Meadow.Config

  require Logger

  @content_type "application/vnd.amazon.eventstream"
  @default_timeout 900_000
  @default_connect_timeout 30_000

  @uint32_size 4
  @checksum_size 4
  @prelude_length @uint32_size * 3
  @message_overhead @prelude_length + @checksum_size

  if Code.ensure_loaded?(:hackney) do
    @doc """
    Returns a stream of decoded Bedrock response events.
    """
    def stream_objects!(%{service: service, data: data} = operation, _opts, config) do
      encoded_body = Jason.encode!(data)
      url = Url.build(operation, config)
      config = Map.put(config, :service_override, :bedrock)

      headers =
        case ExAws.Auth.headers(:post, url, service, config, base_headers(), encoded_body) do
          {:ok, signed_headers} ->
            signed_headers

          {:error, reason} ->
            raise ExAws.Error,
              message: "Failed to sign Bedrock streaming request: #{inspect(reason)}"
        end

      timeout = stream_timeout()

      hackney_opts =
        Application.get_env(:ex_aws, :hackney_opts, [])
        |> Keyword.merge(
          async: :once,
          recv_timeout: timeout,
          connect_timeout: @default_connect_timeout,
          ssl_options: [verify: :verify_peer]
        )

      Logger.debug("Initiating Bedrock streaming request")

      ref =
        case :hackney.post(url, headers, encoded_body, hackney_opts) do
          {:ok, ref} ->
            ref

          {:error, reason} ->
            raise ExAws.Error,
              message: "Failed to initiate Bedrock streaming request: #{inspect(reason)}"
        end

      ref = await_status!(ref, timeout)
      :ok = :hackney.stream_next(ref)
      ref = await_headers!(ref, timeout)

      stream =
        Stream.resource(
          fn -> {:streaming, ref, timeout} end,
          &next_chunk/1,
          &close_stream/1
        )

      Stream.flat_map(stream, &decode_chunk/1)
    end

    defp next_chunk({:streaming, ref, timeout}) do
      :ok = :hackney.stream_next(ref)

      receive do
        {:hackney_response, ^ref, :done} ->
          {:halt, {:closed, ref}}

        {:hackney_response, ^ref, {:status, status, reason}} ->
          message = "#{status}: #{inspect(reason)}"
          raise ExAws.Error, message: "Bedrock streaming failed: #{message}"

        {:hackney_response, ^ref, {:error, reason}} ->
          raise ExAws.Error, message: "Bedrock streaming error: #{inspect(reason)}"

        {:hackney_response, ^ref, data} ->
          {[data], {:streaming, ref, timeout}}
      after
        timeout ->
          raise ExAws.Error,
            message: "Bedrock streaming timed out waiting for data after #{timeout}ms"
      end
    end

    defp next_chunk({:closed, ref}) do
      {:halt, {:closed, ref}}
    end

    defp close_stream({:streaming, ref, _timeout}), do: :hackney.stop_async(ref)
    defp close_stream({:closed, ref}), do: :hackney.stop_async(ref)
    defp close_stream(_), do: :ok

    defp await_status!(ref, timeout) do
      Logger.debug("Waiting for Bedrock streaming status")

      receive do
        {:hackney_response, ^ref, {:status, 200, _reason}} ->
          Logger.debug("Received status 200 from Bedrock")
          ref

        {:hackney_response, ^ref, {:status, status, reason}} ->
          raise ExAws.Error,
            message: "Bedrock streaming request rejected: #{status}: #{inspect(reason)}"

        {:hackney_response, ^ref, {:error, reason}} ->
          raise ExAws.Error, message: "Bedrock streaming connection error: #{inspect(reason)}"
      after
        timeout ->
          raise ExAws.Error,
            message: "Timed out waiting for Bedrock streaming status after #{timeout}ms"
      end
    end

    defp await_headers!(ref, timeout) do
      Logger.debug("Waiting for Bedrock streaming headers")

      receive do
        {:hackney_response, ^ref, {:headers, headers}} ->
          Logger.debug("Received headers from Bedrock: #{inspect(headers)}")
          verify_event_stream!(headers)
          ref

        {:hackney_response, ^ref, {:error, reason}} ->
          raise ExAws.Error, message: "Bedrock streaming headers error: #{inspect(reason)}"

        {:hackney_response, ^ref, other} ->
          Logger.debug("Unexpected message while waiting for headers: #{inspect(other)}")
          await_headers!(ref, timeout)
      after
        timeout ->
          Logger.error("Timed out waiting for Bedrock streaming headers after #{timeout}ms")

          raise ExAws.Error,
            message: "Timed out waiting for Bedrock streaming headers after #{timeout}ms"
      end
    end

    defp verify_event_stream!(headers) do
      verify_header!(headers, "Content-Type", @content_type)
      verify_header!(headers, "Transfer-Encoding", "chunked")
    end

    defp verify_header!(headers, header, expected) do
      case List.keyfind(headers, header, 0) do
        {_, ^expected} ->
          :ok

        {_, value} ->
          raise ExAws.Error,
            message: "Expected #{header} #{inspect(expected)}, received #{inspect(value)}"

        nil ->
          raise ExAws.Error, message: "Missing #{header} header in Bedrock response"
      end
    end
  else
    def stream_objects!(_, _, _) do
      raise "Bedrock response streaming requires hackney; please add {:hackney, \"~> 1.20\"} to Mix dependencies"
    end
  end

  defp base_headers do
    [
      {"accept", @content_type},
      {"content-type", "application/json"},
      {"user-agent", user_agent()},
      {"x-amzn-bedrock-accept", "*/*"}
    ]
  end

  defp user_agent do
    meadow_version = Application.spec(:meadow, :vsn) |> to_string()

    hackney_agent =
      if function_exported?(:hackney_request, :default_ua, 0) do
        :hackney_request.default_ua()
      else
        "hackney"
      end

    [hackney_agent, "meadow/#{meadow_version}", "bedrock-stream/0.1.0"]
    |> Enum.join(" ")
  end

  defp stream_timeout do
    Config.ai(:transcriber_stream_timeout, @default_timeout)
    |> normalize_timeout()
  end

  defp normalize_timeout(timeout) when is_integer(timeout) and timeout > 0, do: timeout

  defp normalize_timeout(timeout) when is_binary(timeout) do
    case Integer.parse(timeout) do
      {int, _} when int > 0 -> int
      _ -> @default_timeout
    end
  end

  defp normalize_timeout(_), do: @default_timeout

  @doc false
  @spec decode_chunk(binary()) ::
          list({:chunk, map()} | {:bad_chunk, binary(), term()} | {:incomplete_chunk, binary()})
  def decode_chunk(data) do
    decode_chunks(data, [])
  end

  defp decode_chunks(<<>>, acc), do: Enum.reverse(acc)

  defp decode_chunks(data, acc) do
    case parse_chunk(data) do
      {:ok, chunk, rest} ->
        decode_chunks(rest, [{:chunk, chunk} | acc])

      {:error, reason, rest} ->
        decode_chunks(rest, [{:bad_chunk, data, reason} | acc])

      :incomplete ->
        Enum.reverse([{:incomplete_chunk, data} | acc])
    end
  end

  defp parse_chunk(
         <<
           message_total_length::unsigned-32,
           headers_length::unsigned-32,
           prelude_checksum::unsigned-32,
           headers::binary-size(headers_length),
           rest::binary
         >> = data
       )
       when byte_size(data) >= message_total_length do
    message_length = message_total_length - @message_overhead
    body_length = message_length - headers_length

    if byte_size(rest) >= body_length + @checksum_size do
      <<
        body::binary-size(body_length),
        message_checksum::unsigned-32,
        next::binary
      >> = rest

      prelude = <<message_total_length::unsigned-32, headers_length::unsigned-32>>

      with :ok <- verify_prelude_checksum(prelude, prelude_checksum),
           :ok <-
             verify_message_checksum(prelude, prelude_checksum, headers, body, message_checksum),
           {:ok, chunk} <- process_chunk(body) do
        {:ok, chunk, next}
      else
        {:error, reason} -> {:error, reason, next}
      end
    else
      :incomplete
    end
  end

  defp parse_chunk(data) when byte_size(data) < @prelude_length, do: :incomplete
  defp parse_chunk(_data), do: {:error, :invalid_chunk, <<>>}

  defp verify_prelude_checksum(prelude, checksum) do
    if crc32(prelude) == checksum do
      :ok
    else
      {:error, :invalid_prelude_checksum}
    end
  end

  defp verify_message_checksum(prelude, prelude_checksum, headers, body, checksum) do
    message = prelude <> <<prelude_checksum::unsigned-32>> <> headers <> body

    if crc32(message) == checksum do
      :ok
    else
      {:error, :invalid_message_checksum}
    end
  end

  defp crc32(data), do: :erlang.crc32(data)

  defp process_chunk(body) do
    # ConverseStream sends plain JSON, Messages API sends double-encoded
    # Try ConverseStream format first (plain JSON)
    Jason.decode(body)
    |> process_decoded_chunk()
  end

  defp process_decoded_chunk({:ok, payload}) when is_map(payload) do
    case payload do
      %{"bytes" => bytes} when is_binary(bytes) ->
        # Messages API: decode base64 then parse inner JSON
        with {:ok, json} <- Base.decode64(bytes),
             {:ok, inner_payload} <- Jason.decode(json) do
          {:ok, inner_payload}
        else
          _ -> {:ok, payload}
        end

      _ ->
        # ConverseStream: already decoded
        {:ok, payload}
    end
  end

  defp process_decoded_chunk({:error, error}), do: {:error, error}
  defp process_decoded_chunk(other), do: {:error, other}
end
