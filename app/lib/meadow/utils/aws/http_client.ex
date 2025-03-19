defmodule Meadow.Utils.AWS.HttpClient do
  @behaviour ExAws.Request.HttpClient

  @moduledoc """
  HTTP client for ExAws requests
  """
  use Retry

  def request(method, url, body \\ "", headers \\ [], http_opts \\ []) do
    http_opts = Application.get_env(:ex_aws, :hackney_opts) |> Keyword.merge(http_opts)

    retry with: exponential_backoff() |> randomize() |> cap(1_000) |> Stream.take(10),
          atoms: [:retry],
          rescue_only: [] do
      case Meadow.HTTP.request(method, url, body, headers, http_opts) do
        {:error, %{reason: :timeout}} ->
          {:retry, :timeout}

        {:ok, %{status_code: status}} = response when status in [429, 503, 504] ->
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
