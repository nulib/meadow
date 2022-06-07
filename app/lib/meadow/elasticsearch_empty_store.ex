defmodule Meadow.ElasticsearchEmptyStore do
  @moduledoc """
  Fetches data to upload to Elasticsearch
  """
  @behaviour Elasticsearch.Store

  @impl true
  def stream(_), do: [] |> Stream.map(& &1)

  @impl true
  def transaction(fun), do: fun.()
end
