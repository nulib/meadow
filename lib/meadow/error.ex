defmodule Meadow.IndexerError, do: defexception([:message])
defmodule Meadow.TimeoutError, do: defexception([:message])
defmodule Meadow.LambdaError, do: defexception([:message])

defmodule Meadow.Error do
  @moduledoc """
  Convenience module for error reporting via Honeybadger
  """
  alias Meadow.Config

  @doc """
  Report an exception to Honeybadger
  """
  def report(exception, module, stacktrace, additional_context \\ %{}) do
    Honeybadger.notify(exception,
      metadata:
        Honeybadger.context()
        |> Map.merge(additional_context)
        |> add_default_metadata(module),
      stacktrace: stacktrace
    )
  end

  @doc """
  Add version and module information to all error reports
  """
  def add_default_metadata(context, module \\ nil) do
    context
    |> Map.merge(%{
      meadow_version: Config.meadow_version(),
      notifier: module
    })
  end
end

defmodule Meadow.Error.Filter do
  @moduledoc """
  Honeybadger message filter for NU-specific sensitive data
  """

  use Honeybadger.Filter.Mixin
  alias Plug.Conn.Cookies

  @redact [~r/^nusso/i, ~r/^_meadow_key$/, ~r/^dcApi/]
  @redacted "[REDACTED]"

  @impl true
  def filter_cgi_data(cgi_data) do
    cgi_data
    |> Map.put("HTTP_COOKIE", cgi_data |> Map.get("HTTP_COOKIE") |> filter_cookie())
  end

  defp filter_cookie(cookie) when is_binary(cookie) do
    cookie
    |> Cookies.decode()
    |> Enum.map(fn {name, value} ->
      if Enum.any?(@redact, &Regex.match?(&1, name)),
        do: "#{name}=#{@redacted}",
        else: "#{name}=#{value}"
    end)
    |> Enum.join("; ")
  end

  defp filter_cookie(cookie), do: cookie
end
