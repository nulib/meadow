defmodule Meadow.SearchIndex.Scroll do
  @moduledoc """
  Retrieves results from the Meadow Elasticsearch cluster and lazily streams one result
  at a time
  """

  alias Meadow.SearchIndex

  def results(query) when is_binary(query) do
    Stream.resource(
      fn -> first(query) end,
      fn cursor -> next(cursor) end,
      fn _ -> :ok end
    )
  end

  defp first(query) do
    with index <- Meadow.Config.current_index() do
      SearchIndex.post!("/#{index}/_search?scroll=10m", query)
    end
  end

  defp next({:ok, %{"_scroll_id" => scroll_id, "hits" => %{"hits" => hits}}})
       when is_list(hits) and length(hits) > 0 do
    {
      hits,
      SearchIndex.post!(
        "/_search/scroll",
        Jason.encode!(%{scroll: "1m", scroll_id: scroll_id})
      )
    }
  end

  defp next(_), do: {:halt, nil}
end
