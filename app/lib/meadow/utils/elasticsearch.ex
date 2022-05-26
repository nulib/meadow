defmodule Meadow.Utils.Elasticsearch do
  def request(method, path, body \\ "", headers \\ [], options \\ []) do
    config = Application.get_env(:meadow, Meadow.Data.Indexer)

    url =
      URI.parse(config[:url])
      |> URI.merge(path)
      |> URI.to_string()

    options = Keyword.merge(config[:default_options], options)

    Elastix.request(method, url, body, headers, options)
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
    do: request("GET", path, "", headers, options)

  def get!(path, headers \\ [], options \\ []),
    do: request!("GET", path, "", headers, options)

  def head(path, headers \\ [], options \\ []),
    do: request("HEAD", path, "", headers, options)

  def head!(path, headers \\ [], options \\ []),
    do: request!("HEAD", path, "", headers, options)

  def post(path, body \\ "", headers \\ [], options \\ []),
    do: request("POST", path, body, headers, options)

  def post!(path, body \\ "", headers \\ [], options \\ []),
    do: request!("POST", path, body, headers, options)

  def put(path, body \\ "", headers \\ [], options \\ []),
    do: request("PUT", path, body, headers, options)

  def put!(path, body \\ "", headers \\ [], options \\ []),
    do: request!("PUT", path, body, headers, options)

  def options(path, headers \\ [], options \\ []),
    do: request("OPTIONS", path, "", headers, options)

  def options!(path, headers \\ [], options \\ []),
    do: request!("OPTIONS", path, "", headers, options)

  def delete(path, headers \\ [], options \\ []),
    do: request("DELETE", path, "", headers, options)

  def delete!(path, headers \\ [], options \\ []),
    do: request!("DELETE", path, "", headers, options)
end
