defmodule Meadow.HTTP.Base do
  @moduledoc """
  Base module for Meadow HTTP clients
  """
  defmacro __using__(_) do
    quote do
      def new(opts \\ []) do
        preprocess_opts(opts)
        |> Req.new()
        |> Req.Request.append_request_steps(
          meadow_user_agent: &Meadow.HTTP.Base.attach_user_agent/1
        )
      end

      def preprocess_opts(opts), do: opts
      defoverridable preprocess_opts: 1

      def get(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :get))
      def get!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :get))
      def post(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :post))
      def post!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :post))
      def put(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :put))
      def put!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :put))
      def delete(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :delete))
      def delete!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :delete))
      def patch(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :patch))
      def patch!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :patch))
      def head(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :head))
      def head!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :head))
      def options(url, opts \\ []), do: request(url, Keyword.put(opts, :method, :options))
      def options!(url, opts \\ []), do: request!(url, Keyword.put(opts, :method, :options))

      def request(url, opts \\ []) do
        new([{:url, url} | opts])
        |> Req.request()
      end

      def request!(url, opts \\ []) do
        new([{:url, url} | opts])
        |> Req.request!()
      end
    end
  end

  def ua do
    meadow_version = Application.spec(:meadow, :vsn) |> to_string()
    finch_version = Application.spec(:finch, :vsn) |> to_string()
    mint_version = Application.spec(:mint, :vsn) |> to_string()
    req_version = Application.spec(:req, :vsn) |> to_string()

    "Meadow/#{meadow_version} (https://github.com/nulib/meadow; contact: repository@northwestern.edu) req/#{req_version} finch/#{finch_version} mint/#{mint_version}"
  end

  def attach_user_agent(request) do
    Req.Request.put_header(request, "user-agent", ua())
  end
end

defmodule Meadow.HTTP do
  @moduledoc """
  Meadow HTTP client with default user agent
  """

  use Meadow.HTTP.Base
end
