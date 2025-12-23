defmodule Meadow.Utils.AWS.HttpClient do
  @behaviour ExAws.Request.HttpClient

  @moduledoc """
  HTTP client for ExAws requests
  """
  use Retry
  require Logger

  def request(method, url, body \\ "", headers \\ [], http_opts \\ []) do
    retry_opts = Application.get_env(:ex_aws, :retry, [])

    max_backoff = Keyword.get(retry_opts, :max_backoff, 1_000)
    max_attempts = Keyword.get(retry_opts, :max_attempts, 10)
    connection_timeout = Application.get_env(:ex_aws, :connection_timeout, 30_000)

    http_opts =
      Application.get_env(:ex_aws, :hackney_opts, [])
      |> Keyword.put_new(:connect_timeout, connection_timeout)
      |> Keyword.merge(http_opts)

    retry with:
          exponential_backoff()
          |> randomize()
          |> cap(max_backoff)
          |> Stream.take(max_attempts),
          atoms: [:retry],
          rescue_only: [] do
      case Meadow.HTTP.request(method, url, body, headers, http_opts) do
        {:error, %HTTPoison.Error{reason: reason}}
        when reason in [:timeout, :connect_timeout, :checkout_timeout] ->
          Logger.warning("Retrying request `#{method} #{url}` due to timeout: #{inspect(reason)}")
          {:retry, reason}

        {:error, %{reason: reason}} when reason in [:timeout, :connect_timeout, :checkout_timeout] ->
          Logger.warning("Retrying request `#{method} #{url}` due to timeout: #{inspect(reason)}")
          {:retry, reason}

        {:ok, %{status_code: status}} = response when status in [429, 503, 504] ->
          Logger.warning("Retrying request `#{method} #{url}` due to status code: #{inspect(status)}")
          {:retry, response}

        {:ok, %HTTPoison.Response{} = result} ->
          {:ok, Map.from_struct(result)}

        error ->
          error
      end
    after
      {:ok, result} -> {:ok, result}
      {:error, error} -> {:error, error}
    else
      {:retry, error} -> error
      error -> error
    end
  end
end
