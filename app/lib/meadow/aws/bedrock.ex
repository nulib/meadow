defmodule Meadow.AWS.Bedrock do
  @moduledoc """
  Bedrock Runtime calls.

  `converse/2` goes through aws-elixir. `converse_stream/2` cannot: Bedrock answers with
  a chunked `application/vnd.amazon.eventstream` body, and aws-elixir's HTTP clients
  buffer whole responses, so streaming is handled by `Meadow.Utils.AWS.BedrockStream`
  over Req.

  Note the endpoint/signing split Bedrock uses: requests go to
  `bedrock-runtime.<region>.amazonaws.com` but are signed for the service name
  `bedrock`. `AWS.BedrockRuntime.metadata/0` carries both, so aws-elixir gets this right
  on its own.
  """

  alias Meadow.AWS.Response
  alias Meadow.Utils.AWS.BedrockStream

  @endpoint_prefix "bedrock-runtime"
  @signing_name "bedrock"

  @doc """
  Invoke the Converse API and return the decoded response body.
  """
  def converse(model_id, body) do
    Meadow.AWS.client(:bedrock)
    |> AWS.BedrockRuntime.converse(model_id, body)
    |> case do
      {:ok, response, _raw} -> {:ok, response}
      other -> Response.unwrap(other)
    end
  end

  @doc """
  Invoke the ConverseStream API, returning a lazy stream of decoded event-stream
  payloads.
  """
  def converse_stream(model_id, body) do
    client = Meadow.AWS.client(:bedrock)
    BedrockStream.stream_objects!(client, url(client, model_id, "converse-stream"), body)
  end

  @doc """
  The service name Bedrock requests are signed for.
  """
  def signing_name, do: @signing_name

  @doc """
  The fully-qualified URL for a Bedrock Runtime model action.
  """
  def url(client, model_id, action) do
    host = Meadow.AWS.host(client, @endpoint_prefix)
    Path.join([Meadow.AWS.endpoint_url(client, host), "model", model_id, action])
  end
end
