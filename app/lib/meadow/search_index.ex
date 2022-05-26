defmodule Meadow.SearchIndex do
  @moduledoc """
  Thin wrapper for Elastix.HTTP that automatically loads the base URL from
  the search index configuration.
  """

  def request(method, path, body \\ "", headers \\ [], options \\ []) do
    config = Application.get_env(:meadow, Meadow.SearchIndex)

    url =
      URI.parse(config[:url])
      |> URI.merge(path)
      |> URI.to_string()

    options = Keyword.merge(config[:default_options], options)

    Elastix.HTTP.request(method, url, stringify(body), headers, options)
  end

  def request!(method, path, body \\ "", headers \\ [], options \\ []) do
    case request(method, path, body, headers, options) do
      {:ok, response} ->
        response

      {:error, error} ->
        raise error
    end
  end

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

  def refresh(index) do
    Application.get_env(:meadow, Meadow.SearchIndex)
    |> Keyword.get(:url)
    |> Elastix.Index.refresh(to_string(index))
  end

  defp stringify(body) when is_binary(body), do: body
  defp stringify(body), do: Jason.encode!(body)
end
