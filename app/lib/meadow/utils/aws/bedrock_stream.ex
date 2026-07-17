defmodule Meadow.Utils.AWS.BedrockStream do
  @moduledoc """
  Minimal helper for consuming AWS Bedrock streaming responses without the
  external `ex_aws_bedrock` dependency.

  It signs the request using `ExAws.Auth`, opens a streaming connection via
  `Req`/`Finch`, and emits decoded event stream payloads.
  """

  alias ExAws.Request.Url
  alias Meadow.Config
  alias Meadow.HTTP
  alias Meadow.Utils.AWS

  require Logger

  @content_type "application/vnd.amazon.eventstream"
  @default_timeout 900_000
  @default_connect_timeout 30_000

  @uint32_size 4
  @checksum_size 4
  @prelude_length @uint32_size * 3
  @message_overhead @prelude_length + @checksum_size

  @doc """
  Returns a stream of decoded Bedrock response events.
  """
  def stream_objects!(%{data: data} = operation, _opts, config) do
    encoded_body = Jason.encode!(data)
    url = Url.build(operation, config)

    timeout = stream_timeout()

    Logger.debug("Initiating Bedrock streaming request")

    resp =
      HTTP.request!(
        url,
        method: :post,
        headers: base_headers(),
        body: encoded_body,
        into: :self,
        receive_timeout: timeout,
        connect_options: [
          timeout: @default_connect_timeout,
          transport_opts: [verify: :verify_peer]
        ],
        retry: false,
        aws_sigv4: AWS.aws_sigv4_options(config, :bedrock)
      )

    verify_status!(resp)
    verify_event_stream!(resp)

    stream =
      Stream.resource(
        fn -> {resp, :streaming} end,
        &next_chunk(&1, timeout),
        &close_stream/1
      )

    Stream.flat_map(stream, &decode_chunk/1)
  end

  defp verify_status!(%Req.Response{status: 200}) do
    Logger.debug("Received status 200 from Bedrock")
    :ok
  end

  defp verify_status!(%Req.Response{status: status} = resp) do
    Req.cancel_async_response(resp)
    raise ExAws.Error, message: "Bedrock streaming request rejected: #{status}"
  end

  defp next_chunk({resp, :done}, _timeout), do: {:halt, {resp, :done}}

  defp next_chunk({resp, :streaming} = state, timeout) do
    ref = resp.body.ref

    receive do
      {^ref, _} = message ->
        case Req.parse_message(resp, message) do
          {:ok, [data: data]} ->
            {[data], state}

          {:ok, [:done]} ->
            {:halt, {resp, :done}}

          {:ok, [trailers: _trailers]} ->
            {[], state}

          {:error, reason} ->
            raise ExAws.Error, message: "Bedrock streaming error: #{inspect(reason)}"
        end
    after
      timeout ->
        raise ExAws.Error,
          message: "Bedrock streaming timed out waiting for data after #{timeout}ms"
    end
  end

  defp close_stream({_resp, :done}), do: :ok
  defp close_stream({resp, :streaming}), do: Req.cancel_async_response(resp)

  defp verify_event_stream!(resp) do
    verify_header!(resp, "content-type", @content_type)
    verify_header!(resp, "transfer-encoding", "chunked")
  end

  defp verify_header!(resp, header, expected) do
    case Req.Response.get_header(resp, header) do
      [^expected] ->
        :ok

      [value] ->
        raise ExAws.Error,
          message: "Expected #{header} #{inspect(expected)}, received #{inspect(value)}"

      [] ->
        raise ExAws.Error, message: "Missing #{header} header in Bedrock response"
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
    "#{Meadow.HTTP.Base.ua()} bedrock-stream/0.1.0"
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
