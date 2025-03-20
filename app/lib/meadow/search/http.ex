defmodule Meadow.Search.HTTP do
  @moduledoc """
  Meadow config-aware wrapper for Elastix.HTTP
  """
  alias Elastix.HTTP, as: ElastixHTTP
  alias Meadow.Error
  alias Meadow.Search.Config, as: SearchConfig

  require Logger

  use Retry

  def get(path, headers \\ [], options \\ []),
    do: request(:get, path, "", headers, options)

  def get!(path, headers \\ [], options \\ []),
    do: request!(:get, path, "", headers, options)

  def head(path, headers \\ [], options \\ []),
    do: request(:head, path, "", headers, options)

  def head!(path, headers \\ [], options \\ []),
    do: request!(:head, path, "", headers, options)

  def post(path, body \\ "", headers \\ [], options \\ []),
    do: request(:post, path, body, headers, options)

  def post!(path, body \\ "", headers \\ [], options \\ []),
    do: request!(:post, path, body, headers, options)

  def put(path, body \\ "", headers \\ [], options \\ []),
    do: request(:put, path, body, headers, options)

  def put!(path, body \\ "", headers \\ [], options \\ []),
    do: request!(:put, path, body, headers, options)

  def options(path, headers \\ [], options \\ []),
    do: request(:options, path, "", headers, options)

  def options!(path, headers \\ [], options \\ []),
    do: request!(:options, path, "", headers, options)

  def delete(path, headers \\ [], options \\ []),
    do: request(:delete, path, "", headers, options)

  def delete!(path, headers \\ [], options \\ []),
    do: request!(:delete, path, "", headers, options)

  def request(method, path, body \\ "", headers \\ [], options \\ [])

  def request(method, path, body, headers, options) when is_map(body),
    do: request(method, path, Jason.encode!(body), headers, options)

  def request(method, path, body, headers, options) do
    with cluster <- SearchConfig.cluster_url(),
         url <- ElastixHTTP.prepare_url(cluster, path) do
      headers = headers |> Keyword.put_new(:"User-Agent", Meadow.HTTP.Base.ua())

      retry with: exponential_backoff() |> randomize() |> cap(1_000) |> Stream.take(10),
            atoms: [:retry],
            rescue_only: [] do
        case ElastixHTTP.request(method, url, body, headers, options) do
          {:ok, %{status_code: status} = response} when status in [429, 503, 504] ->
            {:retry, response}

          {:ok, response} ->
            {:ok, response}

          {:error, %HTTPoison.Error{reason: :timeout} = error} ->
            {:retry, error}

          {:error, error} ->
            {:error, error}

          response ->
            "Unexpected response from Elastix.HTTP.request/5: #{inspect(response)}, method: #{method}, url: #{url}, body: #{body}"
            |> Logger.warning()

            {:error, response}
        end
      after
        result ->
          result |> maybe_report(%{method: method, url: url, body: body})
      else
        {:retry, %HTTPoison.Response{} = response} ->
          response |> maybe_report(%{method: method, url: url, body: body})

        {:retry, reason} ->
          {:error, reason} |> maybe_report(%{method: method, url: url, body: body})

        error ->
          error |> maybe_report(%{method: method, url: url, body: body})
      end
    end
  end

  def request!(method, path, body, headers, options) do
    case request(method, path, body, headers, options) do
      {:ok, response} ->
        response

      {:error, error} ->
        raise error
    end
  end

  defp maybe_report(
         {:error, {:ok, %HTTPoison.Response{body: %{"error" => %{"reason" => reason}}}}} =
           response,
         context
       ) do
    Error.report(%HTTPoison.Error{reason: reason}, __MODULE__, [], context)
    response
  end

  defp maybe_report({:error, reason} = response, context) do
    Error.report(inspect(reason), __MODULE__, [], context)
    response
  end

  defp maybe_report(response, _), do: response
end
