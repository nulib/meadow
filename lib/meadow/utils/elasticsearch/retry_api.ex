defmodule Meadow.Utils.Elasticsearch.RetryAPI do
  @moduledoc """
  Wrap an Elasticsearch.API implementation in a retry block
  """

  alias Meadow.Error

  @default_api Elasticsearch.API.HTTP
  @default_interval 1_000
  @default_retries 10

  def configure do
    with config <- Application.get_env(:meadow, Meadow.ElasticsearchCluster),
         api <- config |> Keyword.get(:api, @default_api),
         retry_config <- Application.get_env(:meadow, :elasticsearch_retry, []),
         interval <- retry_config |> Keyword.get(:interval, @default_interval),
         retries <- retry_config |> Keyword.get(:max_retries, @default_retries),
         wrapped_api <- wrap!(api, interval, retries) do
      Application.put_env(
        :meadow,
        Meadow.ElasticsearchCluster,
        config |> Keyword.put(:api, wrapped_api)
      )
    end
  end

  defp wrap!(api, interval, retries),
    do: make_retriable(retriable?(api), api, interval, retries)

  defp retriable?(api),
    do: function_exported?(api, :retriable?, 0) and api.retriable?

  defp make_retriable(true, api, _, _), do: api

  defp make_retriable(false, api, interval, retries) do
    code =
      quote do
        use Retry
        alias Meadow.Utils.Elasticsearch.RetryAPI
        require Logger

        @behaviour Elasticsearch.API

        @impl true
        def request(config, method, url, data, opts) do
          retry with:
                  exponential_backoff()
                  |> randomize()
                  |> cap(unquote(interval))
                  |> Stream.take(unquote(retries)) do
            case unquote(api).request(config, method, url, data, opts) do
              {:ok, %{status_code: status} = response} when status in 200..399 ->
                {:ok, response}

              {:ok, %{status_code: 404} = response} ->
                {:ok, response}

              {:error, error} ->
                {:error, error}

              response ->
                "Unexpected response from #{unquote(api)}.request/5: #{inspect(response)}"
                |> Logger.warn()

                {:error, response}
            end
          after
            result ->
              result |> RetryAPI.maybe_report(%{method: method, url: url, data: data}, __MODULE__)
          else
            error ->
              error |> RetryAPI.maybe_report(%{method: method, url: url, data: data}, __MODULE__)
          end
        end

        def retriable?, do: true
      end

    with {:module, module, _, _} <-
           Module.create(Module.concat([api, Retriable]), code, Macro.Env.location(__ENV__)) do
      module
    end
  end

  def maybe_report(
        {:error, {:ok, %HTTPoison.Response{body: %{"error" => %{"reason" => reason}}}}} =
          response,
        context,
        module
      ) do
    Error.report(%HTTPoison.Error{reason: reason}, module, [], context)
    response
  end

  def maybe_report({:error, reason} = response, context, module) do
    Error.report(inspect(reason), module, [], context)
    response
  end

  def maybe_report(response, _, _), do: response
end
