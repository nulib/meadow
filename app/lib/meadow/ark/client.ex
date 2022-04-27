defmodule Meadow.Ark.Client do
  @moduledoc """
  HTTPoison-based client for the CDLib EZID API
  """

  use HTTPoison.Base
  alias Meadow.Config

  def process_request_headers(headers) do
    with config <- Config.ark_config(),
         credentials <- Base.encode64("#{config.user}:#{config.password}") do
      headers ++ [{"Authorization", "Basic #{credentials}"}, {"Content-Type", "text/plain"}]
    end
  end

  def process_request_url(url) do
    Config.ark_config()
    |> Map.get(:url)
    |> URI.parse()
    |> URI.merge(url)
    |> URI.to_string()
  end
end
