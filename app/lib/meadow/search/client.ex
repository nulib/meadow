defmodule Meadow.Search.Client do
  @moduledoc """
  Defines functions for making Search requests via the OpenSearch HTTP API
  """

  alias Elastix.HTTP, as: ElastixHTTP
  alias Meadow.{Config, Error}
  alias Meadow.ElasticsearchCluster, as: Cluster

  use Retry
  require Logger

  def delete_by_query(target, query) when is_list(target) do
    target
    |> Enum.map_join(",", &to_string/1)
    |> delete_by_query(query)
  end

  def delete_by_query(target, query) when is_atom(target),
    do: target |> to_string() |> delete_by_query(query)

  def delete_by_query(target, query) do
    with cluster <- Config.elasticsearch_url(),
         url <- ElastixHTTP.prepare_url(cluster, [target, "_delete_by_query"]),
         query <- json_encode(query) do
      case request(:post, url, query) do
        {:ok, %{body: %{"deleted" => deleted}}} ->
          Logger.info("Deleting #{deleted} documents from #{target}")
          {:ok, deleted}

        {:ok, %{body: %{"error" => %{"reason" => reason}}}} ->
          {:error, reason}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    end
  end

  def indexed_doc_count(target) do
    with cluster <- Config.elasticsearch_url(),
         url <-
           ElastixHTTP.prepare_url(cluster, [target, "_count"]) do
      case request(:get, url) do
        {:ok, %{body: %{"count" => count}}} -> {:ok, count}
        {:ok, %{body: %{"error" => %{"reason" => reason}}}} -> {:error, reason}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def latest_v2_indexed_time(model) do
    with target <- Config.v2_index(model),
         query <- %{
           query: %{
             match_all: %{}
           },
           size: 1,
           sort: [%{indexed_at: %{order: "desc"}}]
         } do
      case search(target, query) do
        {:ok, []} ->
          {:ok, "1970-01-01"}

        {:ok, [hit]} ->
          {:ok, hit["_source"]["indexed_at"]}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def reindex(model, indexed_at) when is_atom(model) do
    model = Config.search_model_from_schema(model)
    reindex(model, indexed_at)
  end

  def reindex(model, indexed_at) do
    with cluster <- Config.elasticsearch_url(),
         url <-
           ElastixHTTP.prepare_url(cluster, "_reindex")
           |> ElastixHTTP.append_query_string(wait_for_completion: false),
         query <- reindex_query(model, indexed_at) do
      case request(:post, url, query, recv_timeout: 20_000) do
        {:ok, %{body: %{"task" => task}}} ->
          {:ok, task}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp reindex_query(model, indexed_at) do
    %{
      source: %{
        index: Config.v1_index(),
        query: %{
          bool: %{
            must: [
              %{
                term: %{
                  "model.name.keyword": %{
                    value: model
                  }
                }
              },
              %{
                range: %{
                  indexed_at: %{
                    gt: indexed_at
                  }
                }
              }
            ]
          }
        }
      },
      dest: %{
        index: Config.v2_index(model),
        pipeline: model |> Config.v2_index() |> Config.v2_pipeline()
      }
    }
    |> json_encode()
  end

  def search(target, query)

  def search(target, query)
      when is_list(target) do
    target
    |> Enum.join(",")
    |> search(query)
  end

  def search(target, query) do
    with cluster <- Config.elasticsearch_url(),
         url <- ElastixHTTP.prepare_url(cluster, [target, "_search"]),
         query <- json_encode(query) do
      case request(:post, url, query) do
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
  end

  def task_completed?(nil), do: true

  def task_completed?(task_id) do
    with cluster <- Config.elasticsearch_url(),
         url <-
           ElastixHTTP.prepare_url(cluster, [
             "_tasks",
             task_id
           ]) do
      case request(:get, url) do
        {:ok, %{body: %{"completed" => completed}}} -> completed
        _ -> true
      end
    end
  end

  def task_created_count(task_id) do
    with cluster <- Config.elasticsearch_url(),
         url <-
           ElastixHTTP.prepare_url(cluster, [
             "_tasks",
             task_id
           ]) do
      case request(:get, url) do
        {:ok, %{body: %{"response" => %{"created" => created}}}} -> {:ok, created}
        _ -> {:error, "No task found for #{task_id}"}
      end
    end
  end

  defp json_encode(val) do
    with mod <- :meadow |> Application.get_env(Cluster) |> get_in([:json_library]) do
      mod.encode!(val)
    end
  end

  defp request(method, url, body \\ "", options \\ []) do
    retry with: exponential_backoff() |> randomize() |> cap(1_000) |> Stream.take(10),
          atoms: [:retry],
          rescue_only: [] do
      case ElastixHTTP.request(method, url, body, [], options) do
        {:ok, %{status_code: status} = response} when status in 200..399 ->
          {:ok, response}

        {:ok, %{status_code: 404} = response} ->
          {:ok, response}

        {:ok, %{status_code: 429} = response} ->
          {:retry, response}

        {:error, error} ->
          {:error, error}

        response ->
          "Unexpected response from Elastix.HTTP.request/5: #{inspect(response)}"
          |> Logger.warn()

          {:error, response}
      end
    after
      result ->
        result |> maybe_report(%{method: method, url: url, body: body})
    else
      error ->
        error |> maybe_report(%{method: method, url: url, body: body})
    end
  end

  defp maybe_report(
         {:error, {:ok, %HTTPoison.Response{body: %{"error" => %{"reason" => reason}}}}} =
           response,
         context
       ) do
    Error.report(%HTTPoison.Error{reason: reason}, __MODULE__, [], context)
    response
  end

  defp maybe_report({:error, reason} = response, context) do
    Error.report(inspect(reason), __MODULE__, [], context)
    response
  end

  defp maybe_report(response, _), do: response
end
