defmodule Meadow.HTTP.Base do
  @moduledoc """
  Base module for Meadow HTTP clients
  """
  defmacro __using__(_) do
    quote do
      use HTTPoison.Base

      @callback reprocess_request_headers(headers :: Keyword.t()) :: Keyword.t()

      def process_request_headers(headers) do
        headers
        |> Keyword.put_new(:"User-Agent", Meadow.HTTP.Base.ua())
        |> reprocess_request_headers()
      end

      def reprocess_request_headers(headers), do: headers
      defoverridable reprocess_request_headers: 1
    end
  end

  def ua do
    meadow_version = Application.spec(:meadow, :vsn) |> to_string()
    hackney_version = Application.spec(:hackney, :vsn) |> to_string()
    httpoison_version = Application.spec(:httpoison, :vsn) |> to_string()

    "Meadow/#{meadow_version} (https://github.com/nulib/meadow; contact: repository@northwestern.edu) httpoison/#{httpoison_version} hackney/#{hackney_version}"
  end
end

defmodule Meadow.HTTP do
  @moduledoc """
  Meadow HTTP client
  """
  use Meadow.HTTP.Base
end
