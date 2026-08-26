defmodule Meadow.AWS.HTTPClient do
  @moduledoc """
  `AWS.HTTPClient` implementation backed by `Meadow.HTTP` (Req over Finch).

  aws-elixir ships Finch and hackney clients, but neither fits Meadow well: the Finch
  client needs a named pool that isn't running yet when `Meadow.Config.Runtime` reads
  Secrets Manager, and hackney is a second HTTP stack to configure and tune. Going
  through `Meadow.HTTP` means AWS traffic uses the same Req pipeline — and the same
  user-agent — as the rest of Meadow, and works before Meadow's Finch pool exists by
  falling back to the pool Req starts for itself.

  Three Req defaults have to be turned off, because aws-elixir is doing this work
  itself and would be handed the wrong thing otherwise:

    * `decode_body` — aws-elixir decodes the body with the protocol's own JSON/XML
      parser, so it needs the raw binary. Left on, a JSON response would arrive as a
      map and `AWS.JSON.decode!/2` would fail on it.
    * `redirect` — a signature is only valid for the host it was computed for, and
      aws-elixir branches on statuses (a 307 from a new bucket, say) that following the
      redirect would hide.
    * `retry` — `AWS.Client.request/6` has its own retry policy with backoff and
      jitter, driven by `enable_retries?`. Retrying underneath it would double up, and
      replaying a signed request later risks tripping the request-expiry window.
  """

  @behaviour AWS.HTTPClient

  # Timeout options aws-elixir may pass through from a caller's request options.
  @request_options [:pool_timeout, :receive_timeout, :connect_options]

  @impl AWS.HTTPClient
  def request(method, url, body, headers, options) do
    opts =
      options
      |> Keyword.take(@request_options)
      |> Keyword.merge(
        method: method,
        headers: headers,
        body: body,
        decode_body: false,
        redirect: false,
        retry: false
      )
      |> put_finch()

    case Meadow.HTTP.request(IO.iodata_to_binary(url), opts) do
      {:ok, %Req.Response{status: status, headers: headers, body: body}} ->
        {:ok, %{status_code: status, headers: flatten_headers(headers), body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Meadow's pool once the supervision tree is up; Req's own pool before that.
  defp put_finch(opts) do
    if Process.whereis(Meadow.FinchPool) do
      Keyword.put(opts, :finch, [name: Meadow.FinchPool])
    else
      opts
    end
  end

  # Req groups repeated headers into `%{name => [value]}`; aws-elixir reads response
  # headers as a flat list of two-tuples.
  defp flatten_headers(headers) do
    Enum.flat_map(headers, fn {name, values} ->
      Enum.map(values, &{name, &1})
    end)
  end
end
