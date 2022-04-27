defmodule Meadow.Utils.Elasticsearch.Scroll do
  @moduledoc """
  Retrieves results from the Meadow Elasticsearch cluster and lazily streams one result
  at a time
  """

  def results(query) when is_binary(query) do
    Stream.resource(
      fn -> first(query) end,
      fn cursor -> next(cursor) end,
      fn _ -> :ok end
    )
  end

  defp first(query) do
    Meadow.ElasticsearchCluster
    |> Elasticsearch.post("/meadow/_search?scroll=10m", query)
  end

  defp next({:ok, %{"_scroll_id" => scroll_id, "hits" => %{"hits" => hits}}})
       when is_list(hits) and length(hits) > 0 do
    {
      hits,
      Elasticsearch.post(
        Meadow.ElasticsearchCluster,
        "/_search/scroll",
        Jason.encode!(%{scroll: "1m", scroll_id: scroll_id})
      )
    }
  end

  defp next(_), do: {:halt, nil}
end
