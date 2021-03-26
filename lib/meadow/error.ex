defmodule Meadow.TimeoutError, do: defexception([:message])
defmodule Meadow.LambdaError, do: defexception([:message])

defmodule Meadow.Error do
  @moduledoc """
  Convenience module for error reporting via Honeybadger
  """
  alias Meadow.Config

  def report(exception, module, stacktrace, additional_context \\ %{}) do
    Honeybadger.notify(exception,
      metadata:
        Honeybadger.context()
        |> Map.merge(additional_context)
        |> add_default_metadata(module),
      stacktrace: stacktrace
    )
  end

  def add_default_metadata(context, module \\ nil) do
    context
    |> Map.merge(%{
      meadow_version: Config.meadow_version(),
      notifier: module
    })
    |> add_tag("backend")
  end

  def add_tag(metadata, new_tag) do
    tag_list =
      with tags <- Map.get(metadata, :tags) do
        [tags, new_tag]
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.join(",")
      end

    Map.put(metadata, :tags, tag_list)
  end
end

defmodule Meadow.Error.Filter do
  @moduledoc """
  Honeybadger message filter for NU-specific sensitive data
  """
  @behaviour Honeybadger.NoticeFilter

  alias Plug.Conn.Cookies

  @redact [~r/^nusso/i, ~r/^_meadow_key$/, ~r/^dcApi/]
  @redacted "[REDACTED]"

  def filter(message) do
    with result <- Honeybadger.NoticeFilter.Default.filter(message) do
      Map.put(result, :request, filter_request(result.request))
    end
  end

  defp filter_request(%{cgi_data: cgi_data} = request) when is_map(cgi_data) do
    request |> Map.put(:cgi_data, filter_cgi_data(cgi_data))
  end

  defp filter_request(request), do: request

  defp filter_cgi_data(cgi_data) do
    cgi_data
    |> Map.put("HTTP_COOKIE", cgi_data |> Map.get("HTTP_COOKIE") |> filter_cookie())
  end

  def filter_cookie(cookie) when is_binary(cookie) do
    cookie
    |> Cookies.decode()
    |> Enum.map(fn {name, value} ->
      if Enum.any?(@redact, &Regex.match?(&1, name)),
        do: "#{name}=#{@redacted}",
        else: "#{name}=#{value}"
    end)
    |> Enum.join("; ")
  end

  def filter_cookie(cookie), do: cookie
end
