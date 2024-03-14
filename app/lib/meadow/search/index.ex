defmodule Meadow.Search.Index do
  @moduledoc """
  Meadow config-aware wrapper for Elastix.Index
  """
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.{Alias, HTTP}

  @doc """
  Create a timestamped index based on the config for the given schema and version.
  Returns `{:ok, {alias, index}}`
  """
  def create_from_schema(schema, version) do
    with target <- SearchConfig.alias_for(schema, version),
         settings <- SearchConfig.settings_for(schema, version) do
      create(target, settings)
    end
  end

  @doc """
  Create a timestamped index based on the given alias name.
  Returns `{:ok, {alias, index}}`
  """
  def create(alias, settings \\ %{}) when is_binary(alias) and is_map(settings) do
    case get_in(settings, ["settings", "default_pipeline"]) do
      nil ->
        :noop

      pipeline ->
        pipeline
        |> create_ingest_pipeline(SearchConfig.embedding_model_id(), "embedding_text")
        |> create_search_pipeline()
    end

    with timestamp <- DateTime.utc_now() |> DateTime.to_unix(:millisecond),
         new_index <- [alias, to_string(timestamp)] |> Enum.join("-") do
      case Elastix.Index.create(SearchConfig.cluster_url(), new_index, settings) do
        {:ok, _response} -> {:ok, {alias, new_index}}
        other -> other
      end
    end
  end

  @doc """
  Create a search pipeline, takes a name, normalization_technique, combination_technique, and a weight field
  Returns name
  """
  def create_search_pipeline(
        name,
        normalization_technique \\ "l2",
        combination_technique \\ "arithmetic_mean",
        weights \\ [0.7, 0.3]
      ) do
    pipeline = %{
      "description" => "Search pipeline for #{name}",
      "request_processors" => [
        %{
          "filter_query" => %{
            "description" => "Restricts requests to publicly visible documents",
            "query" => %{
              "bool" => %{
                "must" => [
                  %{
                    "terms" => %{
                      "visibility" => ["Public", "Institution"]
                    }
                  },
                  %{
                    "term" => %{
                      "published" => true
                    }
                  }
                ]
              }
            }
          }
        }
      ],
      "phase_results_processors" => [
        %{
          "normalization-processor" => %{
            "normalization" => %{
              "technique" => normalization_technique
            },
            "combination" => %{
              "technique" => combination_technique,
              "parameters" => %{
                "weights" => weights
              }
            }
          }
        }
      ]
    }

    HTTP.put(["_search", "pipeline", name], pipeline)
    name
  end

  @doc """
  Create a ingest pipeline, takes a name, model id, source field, and a target field
  Returns name
  """
  def create_ingest_pipeline(name, model_id, source_field, target_field \\ "embedding") do
    model_name = embedding_model_name(model_id)

    pipeline = %{
      "description" => "Ingest pipeline for #{name}",
      "processors" => [
        %{
          "text_embedding" => %{
            "model_id" => model_id,
            "field_map" => %{
              source_field => target_field
            },
            "ignore_failure" => true
          }
        },
        %{
          "set" => %{
            "field" => "embedding_model",
            "value" => model_name,
            "if" => "ctx?.#{target_field} != null"
          }
        },
        %{
          "remove" => %{
            "field" => source_field,
            "ignore_failure" => true
          }
        }
      ]
    }

    HTTP.put(["_ingest", "pipeline", name], pipeline)
    name
  end

  defp embedding_model_name(model_id) do
    case Meadow.Search.HTTP.get(["_plugins", "_ml", "models", model_id]) do
      {:ok, %{status_code: 200, body: %{"name" => name}}} -> name
      _ -> nil
    end
  end

  @doc """
  Delete an index
  """
  def delete(index) do
    Elastix.Index.delete(SearchConfig.cluster_url(), index)
  end

  @doc """
  Return a map of all indexes and their metadata starting with the optional binary prefix
  """
  def list(prefix \\ "") do
    with {:ok, %{body: body}} <-
           HTTP.get(["_cluster", "state", "metadata?filter_path=metadata.indices"]) do
      body
      |> get_in(["metadata", "indices"])
      |> Enum.filter(fn {index, _} -> String.starts_with?(index, prefix) end)
      |> Enum.into(%{})
    end
  end

  @doc """
  Delete all indexes starting with a given alias prefix except for the `leave` latest.
  Always leave the `alias` pointing at the latest version of the index. Returns the list
  of remaining indexes.
  """
  def clean(alias, leave \\ 1) do
    alias
    |> list()
    |> extract_aliases()
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.reverse()
    |> Enum.drop(leave)
    |> Enum.each(fn {index, aliases} ->
      Alias.remove(index, aliases)
      delete(index)
    end)

    set_alias(alias)
    list(alias) |> Map.keys()
  end

  def refresh(target) do
    case Elastix.Index.refresh(SearchConfig.cluster_url(), target) do
      {:ok, _} -> :ok
      other -> other
    end
  end

  defp set_alias(alias) do
    alias
    |> list()
    |> extract_aliases()
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.reverse()
    |> set_alias(alias)
  end

  defp set_alias([], _), do: []
  defp set_alias([{latest, _} | _], alias), do: Alias.update(alias, latest)

  defp extract_aliases(index_metadata) do
    index_metadata
    |> Enum.map(fn {index, %{"aliases" => aliases}} -> {index, aliases} end)
  end
end
