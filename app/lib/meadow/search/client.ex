defmodule Meadow.Search.Client do
  @moduledoc """
  Defines functions for making Search requests via the OpenSearch HTTP API
  """

  alias Meadow.Error
  alias Meadow.Search.Alias, as: SearchAlias
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.HTTP
  alias Meadow.Search.Index, as: SearchIndex

  require Logger

  def delete_by_query(target, query) when is_list(target) do
    target
    |> Enum.map_join(",", &to_string/1)
    |> delete_by_query(query)
  end

  def delete_by_query(target, query) when is_atom(target),
    do: target |> to_string() |> delete_by_query(query)

  def delete_by_query(target, query) do
    case HTTP.post([target, "_delete_by_query"], query) do
      {:ok, %{body: %{"deleted" => deleted}}} ->
        Logger.info("Deleting #{deleted} documents from #{target}")
        {:ok, deleted}

      {:ok, %{body: %{"error" => %{"reason" => reason}}}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  def hot_swap(schema, version, func) when is_atom(schema) and is_integer(version) do
    schema
    |> SearchIndex.create_from_schema(version)
    |> perform_hot_swap(func)
  end

  def hot_swap(index, settings, func) when is_binary(index) and is_map(settings) do
    index
    |> SearchIndex.create(settings)
    |> perform_hot_swap(func)
  end

  defp perform_hot_swap({:ok, {alias, index}}, func) do
    case func.(index) do
      :ok ->
        SearchAlias.update(alias, index)

      {:ok, _} ->
        SearchAlias.update(alias, index)

      {:error, reason} ->
        SearchIndex.delete(index)

        Error.log_and_report(
          "Problem performing hot swap",
          reason,
          __MODULE__,
          []
        )
    end
  end

  defp perform_hot_swap({:error, reason}, _) do
    Error.log_and_report(
      "Problem creating new index",
      reason,
      __MODULE__,
      []
    )
  end

  def indexed_doc_count(schema, version),
    do: indexed_doc_count(SearchConfig.alias_for(schema, version))

  def indexed_doc_count(target) do
    case HTTP.get([target, "_count"]) do
      {:ok, %{body: %{"count" => count}}} -> {:ok, count}
      {:ok, %{body: %{"error" => %{"reason" => reason}}}} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  def most_recent(schema, 1) do
    with index <- SearchConfig.alias_for(schema, 1),
         index_model <- SearchConfig.model_for(schema),
         query <- %{
           query: %{term: %{"model.name.keyword" => %{value: index_model}}},
           size: 1,
           sort: [%{indexed_at: %{order: "desc"}}]
         } do
      retrieve_most_recent(index, query)
    end
  end

  def most_recent(schema, version) do
    SearchConfig.alias_for(schema, version)
    |> most_recent()
  end

  def most_recent(index) do
    with query <- %{
           query: %{match_all: %{}},
           size: 1,
           sort: [%{indexed_at: %{order: "desc"}}]
         } do
      retrieve_most_recent(index, query)
    end
  end

  defp retrieve_most_recent(index, query) do
    case search(index, query) do
      {:ok, []} ->
        {:ok, :all}

      {:ok, [%{"_source" => %{"indexed_at" => result}} | _]} ->
        {:ok, result |> NaiveDateTime.from_iso8601!()}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search(target, query)

  def search(target, query)
      when is_list(target) do
    target
    |> Enum.join(",")
    |> search(query)
  end

  def search(target, query) do
    case HTTP.post([target, "_search"], query) do
      {:ok, %{body: %{"aggregations" => %{"group_by_id" => %{"buckets" => buckets}}}}} ->
        {:ok, buckets}

      {:ok, %{body: %{"hits" => %{"hits" => hits}}}} ->
        {:ok, hits}

      {:ok, %{body: %{"error" => %{"reason" => reason}}}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  def refresh(index) do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:url)
    |> Elastix.Index.refresh(to_string(index))
  end
end
