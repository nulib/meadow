defmodule Meadow.Search.Scroll do
  @moduledoc """
  Retrieves results from the Meadow Search cluster and lazily streams one result
  at a time
  """

  alias Meadow.Search.HTTP
  require Logger

  def results(query, index) when is_binary(query) do
    Stream.resource(
      fn -> first(index, query) end,
      fn cursor -> next(cursor) end,
      fn scroll_id -> finish(scroll_id) end
    )
  end

  defp first(index, query) do
    scroll_result([index, "/_search?scroll=1m"], query)
  end

  defp next({:ok, %{"_scroll_id" => scroll_id, "hits" => %{"hits" => []}}}) do
    {:halt, scroll_id}
  end

  defp next({:ok, %{"_scroll_id" => scroll_id, "hits" => %{"hits" => hits}}}) do
    {
      hits,
      scroll_result(["_search", "scroll"], %{scroll: "1m", scroll_id: scroll_id})
    }
  end

  defp next(_), do: {:halt, nil}

  defp finish(scroll_id) when is_binary(scroll_id) do
    HTTP.delete(["_search", "scroll", scroll_id])
    :ok
  end

  defp finish(_), do: :ok

  defp scroll_result(path, query) do
    case HTTP.post(path, query) do
      {:ok, %{body: body, status_code: 200}} -> {:ok, body}
      {:ok, %{body: body}} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end
end
